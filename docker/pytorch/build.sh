#!/bin/bash
# Build one ISA variant of verificarlo/fuzzy:v2.6.0-pytorch2.2.1-<isa>.
#
#   containers/build.sh <sse2|sse4|avx2|avx512> [podman|docker]
#
# Two stages: Verificarlo v2.6.0 with PRISM's static kernels compiled for the
# variant's -march (Dockerfile.verificarlo), then PyTorch compiled with it
# (Dockerfile.pytorch). The build runs code it has just compiled, so it must
# run on a CPU that supports the variant: an AVX-512 machine for avx512.
# Expect about 20 minutes for the first stage and 45-75 for the second.
#
# VERIFICARLO_SRC reuses an existing v2.6.0 checkout (with submodules) instead
# of cloning one.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
isa=${1:?usage: build.sh <sse2|sse4|avx2|avx512> [podman|docker]}
engine=${2:-podman}
case $isa in
sse2) march=x86-64 ;;
sse4) march=x86-64-v2 ;;
avx2) march=x86-64-v3 ;;
avx512) march=x86-64-v4 ;;
*) echo "unknown ISA: $isa (sse2, sse4, avx2 or avx512)" >&2; exit 2 ;;
esac
if [ "$engine" = podman ]; then extra=(--format docker); pull=(--pull=never); else extra=(); pull=(); fi

src=${VERIFICARLO_SRC:-}
if [ -z "$src" ]; then
    src=$(mktemp -d)/verificarlo
    git clone --branch v2.6.0 --recurse-submodules https://github.com/verificarlo/verificarlo.git "$src"
fi

base=localhost/verificarlo/verificarlo:v2.6.0-$isa
image=verificarlo/fuzzy:v2.6.0-pytorch2.2.1-$isa

"$engine" build "${extra[@]}" --build-arg PRISM_ARCH="$march" \
    -t "$base" -f "$here/Dockerfile.verificarlo" "$src"
"$engine" build "${extra[@]}" "${pull[@]}" \
    --build-arg ORG=localhost/verificarlo --build-arg VERIFICARLO_VERSION="v2.6.0-$isa" \
    --build-arg MARCH="$march" --build-arg ISA="$isa" \
    -t "$image" -f "$here/Dockerfile.pytorch" "$here"

# PRISM's static library must use the variant's vector registers: xmm only for
# sse2 and sse4, ymm for avx2, zmm for avx512.
"$engine" run --rm -e VFC_BACKENDS_LOGGER=False "$image" bash -c \
    'd=$(objdump -d --no-show-raw-insn /usr/local/lib/libprism-static.so)
     echo "libprism-static.so: ymm=$(grep -c %ymm <<<"$d") zmm=$(grep -c %zmm <<<"$d")"'
echo "built $image"
