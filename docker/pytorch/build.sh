#!/bin/bash
# Build one ISA variant of verificarlo/fuzzy:v2.6.0-pytorch2.2.1-<isa>.
#
#   docker/pytorch/build.sh <sse2|sse4|avx2|avx512> [podman|docker]
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
root=$(cd "$here/../.." && pwd)
isa=${1:?usage: build.sh <sse2|sse4|avx2|avx512> [podman|docker]}
engine=${2:-podman}
verificarlo_version=v2.6.0
pytorch_version=2.2.1
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
    git clone --branch "$verificarlo_version" --recurse-submodules https://github.com/verificarlo/verificarlo.git "$src"
fi

base=localhost/verificarlo/verificarlo:$verificarlo_version-$isa
image=verificarlo/fuzzy:$verificarlo_version-pytorch$pytorch_version-$isa

"$engine" build "${extra[@]}" --build-arg PRISM_ARCH="$march" \
    -t "$base" -f "$here/Dockerfile.verificarlo" "$src"
"$engine" build "${extra[@]}" "${pull[@]}" \
    --build-arg BASE="$base" --build-arg VERIFICARLO_VERSION="$verificarlo_version" \
    --build-arg PYTORCH_VERSION="$pytorch_version" \
    --build-arg MARCH="$march" --build-arg ISA="$isa" \
    -t "$image" -f "$here/Dockerfile.pytorch" "$root"

# PRISM's static library must use the variant's vector registers: xmm only for
# sse2 and sse4, ymm for avx2, zmm for avx512. Anything else means Highway
# picked a narrower target than -march (e.g. SSSE3 without
# HWY_DISABLE_PCLMUL_AES).
read -r ymm zmm < <("$engine" run --rm -e VFC_BACKENDS_LOGGER=False "$image" bash -c \
    'd=$(objdump -d --no-show-raw-insn /usr/local/lib/libprism-static.so)
     echo "$(grep -c %ymm <<<"$d") $(grep -c %zmm <<<"$d")"')
echo "libprism-static.so: ymm=$ymm zmm=$zmm"
case $isa in
sse2 | sse4) ok=$(( ymm == 0 && zmm == 0 )) ;;
avx2) ok=$(( ymm > 0 && zmm == 0 )) ;;
avx512) ok=$(( zmm > 0 )) ;;
esac
if [ "$ok" != 1 ]; then
    echo "!! libprism-static.so does not target $march" >&2
    exit 1
fi
echo "built $image"
