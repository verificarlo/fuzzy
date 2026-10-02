#!/bin/bash
# Check that binaries use the vector registers of one x86-64 level:
#
#   check-isa.sh <level> LIBPRISM PATH...
#
# LIBPRISM (libprism-static.so) must use the level's widest registers: xmm
# only for x86-64-v1/v2, ymm for v3, zmm for v4. Anything narrower means
# Highway picked a narrower target than -march (e.g. SSSE3 without
# HWY_DISABLE_PCLMUL_AES). The shared objects and executables under each PATH
# must not use registers wider than the level: an AVX-512 instruction in a
# v3 image is a SIGILL on an AVX2 CPU, and PRISM would not see its operands.
# SSE4 instructions in a v1 image are not detected here.
set -euo pipefail
level=${1:?usage: check-isa.sh <level> LIBPRISM PATH...}
prism=${2:?usage: check-isa.sh <level> LIBPRISM PATH...}
shift 2

count() { objdump -d --no-show-raw-insn "$1" 2>/dev/null | grep -c "%$2" || true; }

ymm=$(count "$prism" ymm)
zmm=$(count "$prism" zmm)
echo "$(basename "$prism"): ymm=$ymm zmm=$zmm"
case $level in
x86-64-v1 | x86-64-v2) ok=$((ymm == 0 && zmm == 0)) forbidden='ymm|zmm' ;;
x86-64-v3) ok=$((ymm > 0 && zmm == 0)) forbidden='zmm' ;;
x86-64-v4) ok=$((zmm > 0)) forbidden='' ;;
*) echo "unknown level: $level" >&2; exit 2 ;;
esac
status=0
if [ "$ok" != 1 ]; then
    echo "$(basename "$prism") does not target $level" >&2
    status=1
fi

[ -n "$forbidden" ] || exit $status
while IFS= read -r -d '' file; do
    file -b "$file" | grep -q '^ELF' || continue
    n=$(objdump -d --no-show-raw-insn "$file" 2>/dev/null | grep -cE "%($forbidden)" || true)
    if [ "$n" -gt 0 ]; then
        echo "$file: $n instructions on ${forbidden//|/ or } registers" >&2
        status=1
    fi
done < <(find "$@" -type f \( -name '*.so*' -o -perm -u+x \) -print0)
exit $status
