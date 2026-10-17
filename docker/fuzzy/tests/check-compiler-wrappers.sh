#!/bin/bash
# Both compilation and linking may be expressed entirely as response files.
set -euo pipefail
march=${1:?usage: check-compiler-wrappers.sh MARCH}
here=$(cd "$(dirname "$0")" && pwd)
wrappers=${FUZZY_WRAPPERS:-$here/wrappers}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"
touch exclude.txt
for language in c c++ f; do
    extension=$language
    if [ "$language" = c++ ]; then extension=cpp; fi
    if [ "$language" = f ]; then
        extension=f90
        cat > probe.f90 <<'F'
function probe() bind(C, name="probe") result(s)
    use iso_c_binding
    real(c_double) :: s
    integer :: i
    s = 0.0_c_double
    do i = 1, 1000
        s = s + 0.1_c_double
    end do
end function
F
    else
        cat > "probe.$extension" <<'C'
#ifdef __cplusplus
extern "C"
#endif
double probe(void) {
    double s = 0;
    for (int i = 0; i < 1000; ++i) s += 0.1;
    return s;
}
C
    fi
    printf '%s\n' '-c' '-O2' '-fPIC' "-march=$march" \
        '--prism-backend=sr' '--prism-backend-dispatch=static' \
        '--inst-fma' '--exclude-file=exclude.txt' \
        "probe.$extension" '-o' "'object.$language.o'" > compile.rsp
    "$wrappers/meson-verificarlo-$language" @compile.rsp
    printf '%s\n' '-shared' '-Wl,--as-needed' "-march=$march" '--prism-backend=sr' \
        '--prism-backend-dispatch=static' '--inst-fma' \
        '--exclude-file=exclude.txt' "'object.$language.o'" '-o' probe.so > link.rsp
    "$wrappers/meson-verificarlo-$language" @link.rsp
    readelf -d probe.so | grep -q 'Shared library: \[libprism-static.so\]'
    readelf -d probe.so | grep -q 'Shared library: \[libinterflop_vfcwrapper.so.0\]'
    VFC_BACKENDS='libinterflop_prism.so --mode=rn' /usr/bin/python3 - <<'PY'
import ctypes
lib = ctypes.CDLL('./probe.so')
lib.probe.restype = ctypes.c_double
values = [lib.probe() for _ in range(10)]
assert len(set(values)) == 1, values
assert abs(values[0] - 100.) < 1e-10, values
PY
    VFC_BACKENDS='libinterflop_prism.so --mode=sr' /usr/bin/python3 - <<'PY'
import ctypes
lib = ctypes.CDLL('./probe.so')
lib.probe.restype = ctypes.c_double
assert len({lib.probe() for _ in range(10)}) > 1, 'response-file build has no stochastic rounding'
PY
    for run in 1 2; do
        VFC_BACKENDS='libinterflop_prism.so --mode=sr --seed=42' /usr/bin/python3 - <<'PY' > "seed.$run"
import ctypes
lib = ctypes.CDLL('./probe.so')
lib.probe.restype = ctypes.c_double
print([lib.probe().hex() for _ in range(10)])
PY
    done
    cmp seed.1 seed.2
    echo "[PASS] $language wrapper compiles and links PRISM response files"
done

# Keep the warning guard independent of the legalization pass: a future
# unsupported operation must still fail even if the driver returns zero.
cat > skipped.py <<'PYCODE'
import sys
print('Unsuported vector size: 12', file=sys.stderr)
PYCODE
if /usr/bin/python3 "$wrappers/check-prism.py" /usr/bin/python3 skipped.py >unsupported.log 2>&1; then
    echo 'skipped-operation warning was accepted' >&2
    exit 1
fi
grep -q 'fuzzy: PRISM skipped operations; refusing this build' unsupported.log
echo '[PASS] compiler adapter rejects skipped PRISM vector operations'
/usr/bin/python3 "$here/check-vector-instrumentation.py" "$march"
