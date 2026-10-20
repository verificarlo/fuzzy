#!/usr/bin/env python3
"""Run a level build on an already prepared Slurm host, then import its image.

The controller needs authenticated SSH access (including any required MFA).
All compilation and image checks happen inside the Slurm allocation.
"""
import hashlib
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import time


def run(arguments, **kwargs):
    return subprocess.run(arguments, check=True, text=True, **kwargs)


def stage_source(ssh, source, revision, destination):
    """Publish one complete, immutable snapshot for concurrent level builds."""
    script = r'''
set -euo pipefail
destination=$1
revision=$2
temporary=$(mktemp -d "${destination}.stage.XXXXXX")
trap 'rm -rf -- "$temporary"' EXIT
tar --extract --file=- --directory="$temporary" --same-permissions --no-same-owner --no-acls --no-xattrs
printf '%s\n' "$revision" > "$temporary/.fuzzy-revision"
(
    flock -x 9
    if [ -e "$destination" ]; then
        test "$(cat "$destination/.fuzzy-revision")" = "$revision"
    else
        mv -- "$temporary" "$destination"
    fi
) 9>"${destination}.lock"
'''
    archive = subprocess.Popen(
        ["git", "-C", str(source), "-c", "tar.umask=0022", "archive", "--format=tar",
         revision, ".dockerignore", "docker/fuzzy", "docker/resources"], stdout=subprocess.PIPE)
    try:
        ssh(["bash", "-c", script, "bash", destination, revision], stdin=archive.stdout)
    finally:
        archive.stdout.close()
        status = archive.wait()
    if status:
        raise SystemExit(f"git archive failed: {status}")


def main():
    level = sys.argv[1]
    isa = {"v1": "sse2", "v2": "sse4", "v3": "avx2", "v4": "avx512"}[level]
    host = os.environ["FUZZY_SLURM_HOST"]
    remote_root = os.environ["FUZZY_SLURM_ROOT"].rstrip("/")
    account = os.environ["FUZZY_SLURM_ACCOUNT"]
    engine = os.environ.get("FUZZY_CONTAINER_ENGINE", "podman")
    source = Path(__file__).resolve().parents[3]
    revision = subprocess.check_output(["git", "-C", str(source), "rev-parse", "HEAD"], text=True).strip()
    dirty = subprocess.check_output(["git", "-C", str(source), "status", "--porcelain",
                                    "--", ".dockerignore", "docker/fuzzy", "docker/resources"], text=True)
    if dirty:
        raise SystemExit("Commit the image sources before submitting a revision-identified build")
    remote_source = f"{remote_root}/sources/{revision}"
    output = f"{remote_root}/builds/{revision}"
    log = f"{output}/build-{level}-%j.log"

    def ssh(arguments, **kwargs):
        return run(["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=20", host,
                    shlex.join(arguments)], **kwargs)

    ssh(["mkdir", "-p", f"{remote_root}/sources", output])
    stage_source(ssh, source, revision, remote_source)
    arguments = ["sbatch", "--parsable", f"--account={account}",
                 f"--job-name=fuzzy-{level}-{revision[:8]}", f"--output={log}",
                 f"{remote_source}/docker/fuzzy/offline/build.sbatch", remote_source,
                 f"{remote_root}/bundle", f"{remote_root}/base-{level}.oci.tar",
                 f"{remote_root}/uv.oci.tar", output, level,
                 f"{remote_root}/intel-sde" if level != "v4" else "",
                 f"{remote_root}/checkpoint-{level}.tar"]
    # Persist the handle at the submission host before the SSH command
    # returns. A controller restart observes that job instead of resubmitting
    # a build whose submission or subsequent observation was interrupted.
    submit_script = ('set -euo pipefail; file=$1; shift; '
                     'if [ -s "$file" ]; then cat "$file"; else "$@" | tee "$file"; fi')
    submitted = ssh(["bash", "-c", submit_script, "bash", f"{output}/job-{level}.id", *arguments], capture_output=True)
    job = submitted.stdout.strip().split(";")[0]
    if not job.isdigit():
        raise SystemExit(f"Unexpected sbatch response: {submitted.stdout}")
    print(f"Submitted Slurm job {job}; log: {log.replace('%j', job)}", flush=True)
    result_root = Path(os.environ.get("RUNNER_TEMP", tempfile.gettempdir())) / f"fuzzy-{revision}-{level}"
    result_root.mkdir(parents=True, exist_ok=True)
    (result_root / "jobid").write_text(job + "\n")
    state = ""
    while True:
        # Observe this exact job; a transient SSH/accounting error never
        # submits another build or cancels the allocation.
        try:
            observed = ssh(["sacct", "-j", job, "-nP", "-o", "JobIDRaw,State,ExitCode"], capture_output=True)
        except subprocess.CalledProcessError:
            print(f"Observation failed for job {job}; retrying the same handle", flush=True)
            time.sleep(30)
            continue
        entries = [line.split("|") for line in observed.stdout.splitlines()]
        entry = next((row for row in entries if row[0] == job), None)
        if entry:
            new_state = entry[1].split()[0].rstrip("+")
            if new_state != state:
                print(f"Slurm job {job}: {new_state}", flush=True)
                state = new_state
            if state == "COMPLETED":
                if entry[2] != "0:0":
                    raise SystemExit(f"Slurm job {job}: {entry[2]}")
                break
            if state in {"FAILED", "CANCELLED", "TIMEOUT", "OUT_OF_MEMORY", "NODE_FAIL", "BOOT_FAIL", "DEADLINE", "PREEMPTED"}:
                ssh(["tail", "-100", log.replace("%j", job)])
                raise SystemExit(f"Slurm job {job}: {state} ({entry[2]})")
        time.sleep(30)

    ssh(["tail", "-100", log.replace("%j", job)])
    archive = result_root / f"{level}.oci.tar"
    run(["rsync", "-a", "--protect-args", "--partial", f"{host}:{output}/{level}.oci.tar", str(archive)])
    expected = ssh(["cat", f"{output}/{level}.oci.tar.sha256"], capture_output=True).stdout.split()[0]
    digest = hashlib.sha256()
    with archive.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    if digest.hexdigest() != expected:
        raise SystemExit("OCI archive checksum mismatch")
    run([engine, "load", "-i", str(archive)])
    version = os.environ.get("FUZZY_VERIFICARLO_VERSION", "v2.7.0")
    image = f"verificarlo/fuzzy:{version}-x86-64-{level}"
    labels = subprocess.check_output([engine, "image", "inspect", "--format",
                                      '{{index .Config.Labels "org.verificarlo.fuzzy.level"}} {{index .Config.Labels "org.verificarlo.version"}}',
                                      image], text=True).strip()
    if labels != f"x86-64-{level} {version}":
        raise SystemExit(f"Unexpected imported image labels: {labels}")
    run([engine, "tag", image, f"verificarlo/fuzzy:{version}-{isa}"])
    print(f"Imported validated image {image} from Slurm job {job}", flush=True)


if __name__ == "__main__":
    main()
