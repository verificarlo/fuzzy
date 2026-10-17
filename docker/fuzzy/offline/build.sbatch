#!/bin/bash
# Submit with: sbatch --account=ACCOUNT build.sbatch SOURCE BUNDLE BASE UV OUTPUT LEVEL [SDE] [CACHE]
# BASE is an OCI archive tagged localhost/fuzzy-offline-base:LEVEL.
# All downloads and source preparation happen before this compute job.
#SBATCH --job-name=fuzzy-level
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=06:00:00
set -euo pipefail
source_input=$(realpath "${1:?SOURCE directory required}")
source_dir=${SLURM_TMPDIR:?}/fuzzy-source
cp -a "$source_input" "$source_dir"
bundle=$(realpath "${2:?BUNDLE directory required}")
base_archive=$(realpath "${3:?BASE OCI archive required}")
uv_archive=$(realpath "${4:?UV OCI archive required}")
output=$(realpath -m "${5:?OUTPUT directory required}")
level=${6:?LEVEL required}
sde=${7:-}
cache_archive=${8:-}
case $level in
    v1) isa=sse2 ;;
    v2) isa=sse4 ;;
    v3) isa=avx2 ;;
    v4) isa=avx512 ;;
    *) echo "Unknown level: $level" >&2; exit 2 ;;
esac
module load podman/4.9.5
mkdir -p "$output"
cd "$bundle"
sha256sum -c SHA256SUMS > "$output/bundle-verification-$level.log"
cd "$source_dir"
find docker/fuzzy docker/resources -type f -print0 | sort -z | \
    xargs -0 sha256sum > "$output/source-$level.sha256"
export FUZZY_OFFLINE_BUNDLE=$bundle
export FUZZY_OFFLINE_STORAGE=${SLURM_TMPDIR:?}/fuzzy-podman
export JOBS=${JOBS:-1} TORCH_BUILD_JOBS=${TORCH_BUILD_JOBS:-8}
export FUZZY_VERIFICARLO_VERSION=v2.7.0 FUZZY_PRISM_VERSION=0.0.12
engine=$source_dir/docker/fuzzy/offline/podman.sh
"$engine" load -i "$base_archive"
"$engine" tag "localhost/fuzzy-offline-base:$level" "localhost/verificarlo/verificarlo:v2.7.0-$isa"
"$engine" load -i "$uv_archive"
if [ -n "$cache_archive" ]; then
    cache_archive=$(realpath -m "$cache_archive")
    if [ -f "$cache_archive" ]; then
        sha256sum -c "$cache_archive.sha256"
        "$engine" load -i "$cache_archive"
    fi
    # Preserve completed stages even if a later build or check fails. A
    # cache never bypasses the normal Dockerfile dependency and test gates.
    checkpoint() {
        result=$?
        trap - EXIT
        (
            mapfile -t images < <("$engine" images --all --no-trunc --format '{{.ID}}' | sort -u)
            [ "${#images[@]}" -gt 0 ] &&
            "$engine" save --quiet --multi-image-archive --format docker-archive \
                -o "$cache_archive.partial" "${images[@]}" &&
            mv "$cache_archive.partial" "$cache_archive" &&
            sha256sum "$cache_archive" > "$cache_archive.sha256"
        ) || echo "Could not save optional stage cache: $cache_archive" >&2
        exit "$result"
    }
    trap checkpoint EXIT
fi
srun --cpu-bind=cores docker/fuzzy/build.sh "$level" "$engine"
image=verificarlo/fuzzy:v2.7.0-x86-64-$level
if [ "$level" != v4 ]; then
    [ -n "$sde" ] || { echo 'SDE directory required for v1-v3 validation' >&2; exit 2; }
    srun --cpu-bind=cores docker/fuzzy/tests/run-sde.sh "$level" "$image" "$sde" "$engine"
fi
"$engine" image inspect --format '{{json .Config.Env}}' "$image" | python3 -c '
import json, sys
settings = json.load(sys.stdin)
assert not any("/opt/fuzzy-offline" in item for item in settings), settings
assert not any(item.startswith(("PIP_NO_INDEX=", "UV_OFFLINE=")) for item in settings), settings
'
"$engine" save --format oci-archive -o "$output/$level.oci.tar" "$image"
sha256sum "$output/$level.oci.tar" > "$output/$level.oci.tar.sha256"
printf 'Validated and exported %s\n' "$image"
