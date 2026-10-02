#!/bin/bash
# Build verificarlo/fuzzy:<verificarlo>-x86-64-v<N> for one x86-64 level:
#
#   docker/fuzzy/build.sh <v1|v2|v3|v4> [podman|docker]
#
# 1. The level's Verificarlo image, with PRISM's static kernels compiled for
#    its -march (docker/pytorch/Dockerfile.verificarlo). Skipped when
#    localhost/verificarlo/verificarlo:<verificarlo>-<isa> exists already,
#    e.g. from docker/pytorch/build.sh; set REBUILD_BASE=1 to rebuild it.
# 2. docker/fuzzy/Dockerfile up to its `test` stage, which runs
#    docker/fuzzy/tests/run.sh, then the `final` stage from the same cache.
#
# The build runs code it has just compiled, so it must run on a CPU that
# supports the level: an AVX-512 machine for v4. VERIFICARLO_SRC reuses an
# existing Verificarlo checkout (with submodules) instead of cloning one.
# JOBS sets how many stages podman builds in parallel (default 2).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
n=${1:?usage: build.sh <v1|v2|v3|v4> [podman|docker]}
engine=${2:-podman}
verificarlo_version=v2.6.0
prism_version=0.0.8
case $n in
v1) march=x86-64 isa=sse2 ;;
v2) march=x86-64-v2 isa=sse4 ;;
v3) march=x86-64-v3 isa=avx2 ;;
v4) march=x86-64-v4 isa=avx512 ;;
*)
    echo "unknown level: $n (v1, v2, v3 or v4)" >&2
    exit 2
    ;;
esac
level=x86-64-$n
if [ "$engine" = podman ]; then
    extra=(--format docker --jobs "${JOBS:-2}")
else
    extra=()
fi

base=localhost/verificarlo/verificarlo:$verificarlo_version-$isa
if [ -n "${REBUILD_BASE:-}" ] || ! "$engine" image inspect "$base" >/dev/null 2>&1; then
    src=${VERIFICARLO_SRC:-}
    if [ -z "$src" ]; then
        src=$(mktemp -d)/verificarlo
        git clone --branch "$verificarlo_version" --recurse-submodules https://github.com/verificarlo/verificarlo.git "$src"
    fi
    "$engine" build "${extra[@]}" --build-arg PRISM_ARCH="$march" \
        -t "$base" -f "$root/docker/pytorch/Dockerfile.verificarlo" "$src"
fi

image=verificarlo/fuzzy:$verificarlo_version-$level
args=(
    --build-arg BASE="$base"
    --build-arg MARCH="$march"
    --build-arg LEVEL="$level"
    --build-arg VERIFICARLO_VERSION="$verificarlo_version"
    --build-arg PRISM_RUNTIME_VERSION="$prism_version+${level//-/.}"
    -f "$here/Dockerfile"
)
start=$(date +%s)
"$engine" build "${extra[@]}" "${args[@]}" --target test -t "localhost/fuzzy-test:$level" "$root"
"$engine" build "${extra[@]}" "${args[@]}" --target final -t "$image" "$root"
"$engine" tag "$image" "verificarlo/fuzzy:$verificarlo_version-$isa"
end=$(date +%s)

echo "built $image (alias verificarlo/fuzzy:$verificarlo_version-$isa)"
echo "build time: $(((end - start) / 60)) min, image size: $("$engine" image inspect "$image" --format '{{.Size}}' | numfmt --to=iec)"
