#!/bin/bash
# Build verificarlo/fuzzy:<verificarlo>-x86-64-v<N> for one x86-64 level:
#
#   docker/fuzzy/build.sh <v1|v2|v3|v4> [podman|docker]
#
# 1. The level's Verificarlo image, with PRISM's static kernels compiled for
#    its -march (the release's own Dockerfile). Skipped when
#    localhost/verificarlo/verificarlo:<verificarlo>-<isa> exists already,
#    e.g. from docker/pytorch/build.sh; set REBUILD_BASE=1 to rebuild it.
# 2. docker/fuzzy/Dockerfile up to its `test` stage, which runs
#    docker/fuzzy/tests/run.sh, then the `final` stage from the same cache.
#
# The build runs code it has just compiled, so it must run on a CPU that
# supports the level: an AVX-512 machine for v4. VERIFICARLO_SRC reuses an
# existing Verificarlo checkout (with submodules) instead of cloning one, and
# VERIFICARLO_REF builds an unreleased commit or ref (e.g. pull/395/head)
# instead of the release tag. FUZZY_VERIFICARLO_VERSION and FUZZY_PRISM_VERSION
# must then match it. (Not VERIFICARLO_VERSION: CI sets it for the per-stack
# images.)
# JOBS sets how many stages podman builds in parallel (default 2).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
n=${1:?usage: build.sh <v1|v2|v3|v4> [podman|docker]}
engine=${2:-podman}
# v2.7.0 includes libprism-config, the libhwy dependency, ROUND_DW and the
# per-ISA build support. Its PRISM submodule is v0.0.12.
verificarlo_version=${FUZZY_VERIFICARLO_VERSION:-v2.7.0}
prism_version=${FUZZY_PRISM_VERSION:-0.0.12}
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
        if [ -n "${VERIFICARLO_REF:-}" ]; then
            git init -q "$src"
            git -C "$src" fetch -q --depth 1 https://github.com/verificarlo/verificarlo.git "$VERIFICARLO_REF"
            git -C "$src" checkout -q FETCH_HEAD
            git -C "$src" submodule update -q --init --recursive
        else
            git clone --branch "$verificarlo_version" --recurse-submodules https://github.com/verificarlo/verificarlo.git "$src"
        fi
    fi
    "$engine" build "${extra[@]}" --build-arg PRISM_ARCH="$march" \
        -t "$base" -f "$src/Dockerfile" "$src"
fi

image=verificarlo/fuzzy:$verificarlo_version-$level
args=(
    --build-arg BASE="$base"
    --build-arg MARCH="$march"
    --build-arg LEVEL="$level"
    --build-arg VERIFICARLO_VERSION="$verificarlo_version"
    --build-arg PRISM_RUNTIME_VERSION="$prism_version+${level//-/.}"
    --build-arg TORCH_BUILD_JOBS="${TORCH_BUILD_JOBS:-2}"
    -f "$here/Dockerfile"
)
start=$(date +%s)
"$engine" build "${extra[@]}" "${args[@]}" --target test -t "localhost/fuzzy-test:$level" "$root"
"$engine" build "${extra[@]}" "${args[@]}" --target final -t "$image" "$root"
"$engine" tag "$image" "verificarlo/fuzzy:$verificarlo_version-$isa"
end=$(date +%s)

echo "built $image (alias verificarlo/fuzzy:$verificarlo_version-$isa)"
echo "build time: $(((end - start) / 60)) min, image size: $("$engine" image inspect "$image" --format '{{.Size}}' | numfmt --to=iec)"
