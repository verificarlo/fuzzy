#!/usr/bin/env python3
"""Stage the release's sources and build wheels for an offline Podman build.

Run on a networked machine with CPython 3.12 and pip:
    python3 prepare.py BUNDLE
The bundle is mounted at /opt/fuzzy-offline by podman.sh; it is never copied
into the image. Source archives retain git metadata needed by build scripts.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile


ARCHIVES = [
    "https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v3.12.1.tar.gz",
    "https://www.python.org/ftp/python/3.12.13/Python-3.12.13.tar.xz",
    "https://github.com/numpy/numpy/releases/download/v2.4.6/numpy-2.4.6.tar.gz",
    "https://github.com/scikit-learn/scikit-learn/archive/refs/tags/1.9.0.tar.gz",
]
REPOSITORIES = [
    ("https://github.com/scipy/scipy.git", "v1.18.0"),
    ("https://github.com/pytorch/pytorch.git", "v2.5.1"),
    ("https://github.com/pytorch/audio.git", "v2.5.1"),
    ("https://github.com/pytorch/vision.git", "v0.20.1"),
]
BUILD_REQUIREMENTS = [
    "pip", "setuptools<75", "wheel", "cmake<4", "ninja", "meson-python",
    "cython", "pythran", "pybind11", "packaging", "pillow", "pytest",
    "joblib", "threadpoolctl", "sympy==1.13.1", "filelock", "networkx",
    "jinja2", "fsspec", "typing_extensions", "requests",
]


def run(*arguments):
    print("+", *arguments, flush=True)
    subprocess.run(arguments, check=True)


def digest(path):
    result = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            result.update(block)
    return result.hexdigest()


def main():
    if sys.version_info[:2] != (3, 12):
        raise SystemExit("Use CPython 3.12 to stage the image's build wheels")
    bundle = Path(sys.argv[1]).resolve()
    sources = bundle / "sources"
    wheels = bundle / "wheels"
    sources.mkdir(parents=True, exist_ok=True)
    wheels.mkdir(exist_ok=True)
    index_path = bundle / "sources.json"
    index = json.loads(index_path.read_text()) if index_path.exists() else {}

    def record(key, path):
        index[key] = {"file": str(path.relative_to(bundle)), "sha256": digest(path)}
        index_path.write_text(json.dumps(index, indent=2) + "\n")

    for url in ARCHIVES:
        name = hashlib.sha256(url.encode()).hexdigest()[:16] + "-" + url.rsplit("/", 1)[1]
        path = sources / name
        if not path.exists():
            partial = path.with_suffix(path.suffix + ".partial")
            run("curl", "--fail", "--location", "--retry", "3", url, "--output", str(partial))
            partial.rename(path)
        record(url, path)

    with tempfile.TemporaryDirectory(prefix="fuzzy-prefetch-") as temporary:
        work = Path(temporary)
        requirement_files = []
        for url, ref in REPOSITORIES:
            key = url + "@" + ref
            name = url.rsplit("/", 1)[1].removesuffix(".git") + "-" + ref
            path = sources / (name + ".tar")
            checkout = work / name
            if not path.exists():
                run("git", "clone", "--quiet", "--depth=1", "--branch", ref,
                    "--recurse-submodules", "--shallow-submodules", url, str(checkout))
                partial = path.with_suffix(".partial")
                with tarfile.open(partial, "w") as archive:
                    archive.add(checkout, arcname=".")
                partial.rename(path)
            else:
                checkout.mkdir()
                with tarfile.open(path) as archive:
                    archive.extractall(checkout, filter="data")
            record(key, path)
            if "pytorch/pytorch.git" in url:
                requirement_files.append(checkout / "requirements.txt")

        # NumPy's build requirements are maintained in its release archive.
        numpy_key = next(url for url in ARCHIVES if "/numpy/" in url)
        numpy_archive = bundle / index[numpy_key]["file"]
        with tarfile.open(numpy_archive) as archive:
            archive.extractall(work, filter="data")
        requirement_files.append(work / "numpy-2.4.6/requirements/build_requirements.txt")
        arguments = [sys.executable, "-m", "pip", "download", "--only-binary=:all:",
                     "--dest", str(wheels), *BUILD_REQUIREMENTS]
        for requirement in requirement_files:
            arguments += ["-r", str(requirement)]
        print("+", *arguments, flush=True)
        # Stage the public build dependencies from PyPI, without inheriting
        # workstation-specific package indexes that the cluster cannot use.
        environment = dict(os.environ, PIP_CONFIG_FILE=os.devnull,
                           PIP_INDEX_URL="https://pypi.org/simple", PIP_EXTRA_INDEX_URL="")
        subprocess.run(arguments, check=True, env=environment)

    binaries = bundle / "bin"
    binaries.mkdir(exist_ok=True)
    shutil.copy2(Path(__file__).with_name("tool.py"), binaries / "tool.py")
    for name in ("git", "wget", "uv", "apt-get"):
        link = binaries / name
        if not link.exists():
            link.symlink_to("tool.py")
    (bundle / "SHA256SUMS").write_text("".join(
        f"{digest(path)}  {path.relative_to(bundle)}\n"
        for path in sorted([*sources.iterdir(), *wheels.iterdir()]) if path.is_file()))
    print(f"Prepared {bundle}; verify with: cd {bundle} && sha256sum -c SHA256SUMS")


if __name__ == "__main__":
    main()
