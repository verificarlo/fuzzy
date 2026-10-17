#!/bin/bash
# Checks run by the `test` stage of docker/fuzzy/Dockerfile:
#
#   tests/run.sh <level>     (x86-64-v1 ... x86-64-v4)
#
# For every package: the prism build varies under --mode=sr, the ieee build
# does not, and prism --mode=rn stays within MAX_ULP of ieee. PRISM's rn does
# not break ties like IEEE round-to-nearest, so rn is not expected to be bit
# for bit identical, but a missing -march, an FMA or an instrumentation
# mismatch shows up as a much larger difference. Then mixed selections, the
# PRISM libraries' dependencies, the ISA of every binary, RUNPATHs, and the
# fuzzy tool itself.
set -euo pipefail
trap 'echo "run.sh:$LINENO: \"$BASH_COMMAND\" failed" >&2' ERR
level=${1:?usage: run.sh <level>}
here=$(cd "$(dirname "$0")" && pwd)
MAX_ULP=${MAX_ULP:-16}
RUNS=${RUNS:-5}
SR="libinterflop_prism.so --mode=sr"
RN="libinterflop_prism.so --mode=rn"
sys_python=/usr/bin/python3
work=$(mktemp -d)
failures=0

pass() { echo "[PASS] $*"; }
fail() {
    echo "[FAIL] $*"
    failures=$((failures + 1))
}

# distinct NAME CMD...: number of distinct outputs over $RUNS runs of CMD.
distinct() {
    local name=$1 i
    shift
    for i in $(seq "$RUNS"); do "$@" >"$work/$name.$i"; done
    md5sum "$work/$name".* | cut -d' ' -f1 | sort -u | wc -l
}

varies() {
    local name=$1 n
    shift
    n=$(distinct "$name" "$@")
    if [ "$n" -gt 1 ]; then pass "$name varies ($n/$RUNS distinct)"; else fail "$name does not vary"; fi
}

constant() {
    local name=$1 n
    shift
    n=$(distinct "$name" "$@")
    if [ "$n" -eq 1 ]; then pass "$name is constant"; else fail "$name varies ($n/$RUNS distinct)"; fi
}

# close NAME IEEE_CMD -- PRISM_CMD: prism --mode=rn within MAX_ULP of ieee.
close() {
    local name=$1 ieee=() result
    shift
    while [ "$1" != -- ]; do
        ieee+=("$1")
        shift
    done
    shift
    "${ieee[@]}" >"$work/$name.ieee"
    VFC_BACKENDS=$RN "$@" >"$work/$name.rn"
    if result=$($sys_python "$here/ulpdiff.py" "$work/$name.ieee" "$work/$name.rn" "$MAX_ULP" 2>&1); then
        pass "$name: prism rn vs ieee, $result"
    else
        fail "$name: prism rn vs ieee, $result"
    fi
}

# A shared runtime must apply precision settings even when a plain program
# loads the first instrumented extension late in its lifetime.
precision() {
    local name=$1
    shift
    VFC_BACKENDS=$RN "$@" >"$work/$name.full"
    VFC_BACKENDS="$RN --precision-binary64=40 --precision-binary32=16" "$@" >"$work/$name.reduced"
    if cmp -s "$work/$name.full" "$work/$name.reduced"; then
        fail "$name ignores reduced precision"
    else
        pass "$name applies reduced precision"
    fi
}

export VFC_BACKENDS=$SR
echo "== Release and defaults"
expected=${FUZZY_VERIFICARLO_VERSION:-v2.7.0}
actual=$(verificarlo-c --version)
if [[ $expected =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    if [ "$actual" = "verificarlo ${expected#v}" ]; then
        pass "Verificarlo release $expected"
    else
        fail "expected $expected, got $actual"
    fi
fi
fuzzy list >"$work/default-selection"
for pkg in lapack python libm numpy scipy sklearn torch torchaudio torchvision; do
    if awk -v pkg="$pkg" '$1 == pkg && $5 == "prism" { found = 1 } END { exit !found }' "$work/default-selection"; then
        pass "$pkg defaults to prism"
    else
        fail "$pkg does not default to prism"
    fi
done
# The other checks select libm themselves. With libm=ieee, the preloaded
# library is empty: nothing loads PRISM before the package under test does.
fuzzy use libm=ieee >/dev/null

march=$level
if [ "$level" = x86-64-v1 ]; then march=x86-64; fi
"$here/check-compiler-wrappers.sh" "$march"

echo "== PRISM libraries"
# Each must load on its own, from an uninstrumented program, and share one
# run-time configuration (verificarlo/prism#23, #24).
for lib in /usr/local/lib/libprism-static.so /usr/local/lib/libprism-dynamic.so; do
    needed=$(readelf -d "$(readlink -f "$lib")" | grep NEEDED)
    for dep in libhwy.so libprism-config.so; do
        if grep -q "\[$dep\]" <<<"$needed"; then
            pass "$(basename "$lib") needs $dep"
        else
            fail "$(basename "$lib") does not need $dep"
        fi
    done
done

echo "== LAPACK"
clang -O2 "$here/test_blas.c" -o "$work/test_blas" -L"$FUZZY_ROOT/active/lib" -lblas -llapack
blas() { fuzzy run "lapack=$1" -- "$work/test_blas"; }
varies lapack-prism blas prism
constant lapack-ieee blas ieee
close lapack blas ieee -- blas prism
precision lapack blas prism

echo "== CPython"
python_probe='
import math
s = 0.0
for _ in range(1000):
    s += 0.001
print(s.hex(), sum([0.001] * 1000).hex(), math.prod([1.1] * 100).hex())'
py() { fuzzy run "python=$1" -- "$FUZZY_ROOT/python/3.12/bin/python3" -c "$python_probe"; }
varies python-prism py prism
constant python-ieee py ieee
close python py ieee -- py prism
precision python py prism
# Not checked: sum() of floats. Since 3.12 it uses Neumaier compensated
# summation, whose error term is computed by exact operations; stochastic
# rounding leaves exact operations unchanged, so the compensation recovers
# the rounding errors and sum([0.001] * 1000) is the same in every run.

echo "== NumPy"
for build in ieee prism; do
    uv venv -q "$work/numpy-$build" --python "$FUZZY_ROOT/python/3.12/bin/python3"
    fuzzy use --python "$work/numpy-$build" "numpy=$build" >/dev/null
done
uv pip install -q --python "$work/numpy-prism" pytest
# Random inputs: numpy.random is not instrumented, so both builds get the
# same data, and unlike constant arrays it rarely produces ties, where PRISM's
# rn and IEEE round-to-nearest differ. The matrix is well conditioned.
numpy_probe='
import numpy as np
rng = np.random.default_rng(0)
x = rng.random(10000)
a = rng.random((64, 64)) + 64 * np.eye(64)
print(np.add.reduce(x).hex(), (x * x).sum().hex(),
      *[v.hex() for v in (a @ a[:, :2]).ravel()[:8]],
      *[v.hex() for v in np.linalg.solve(a, x[:64])[:8]])'
# A single scalar reduction usually has only two possible rounded outputs.
# Sample several independent results so five stochastic runs cannot easily
# coincide and falsely look like an uninstrumented package.
np_reduce() { fuzzy run "python=ieee" "lapack=$2" -- "$work/numpy-$1/bin/python" -c "import numpy as np; x = np.full(10000, 0.1); print(*(np.add.reduce(x).hex() for _ in range(16)))"; }
np_dot() { fuzzy run "python=ieee" "lapack=$2" -- "$work/numpy-$1/bin/python" -c "import numpy as np; a = np.full((64, 64), 0.1); print(*(v.hex() for v in np.dot(a, 2 * a)[0, :8]))"; }
np_all() { fuzzy run "python=ieee" "lapack=$2" -- "$work/numpy-$1/bin/python" -c "$numpy_probe"; }
# numpy's own loops follow the numpy build, BLAS calls follow lapack.
varies numpy-prism.lapack-ieee:reduce np_reduce prism ieee
constant numpy-prism.lapack-ieee:dot np_dot prism ieee
constant numpy-ieee.lapack-prism:reduce np_reduce ieee prism
varies numpy-ieee.lapack-prism:dot np_dot ieee prism
constant numpy-ieee.lapack-ieee np_all ieee ieee
varies numpy-prism.lapack-prism np_all prism prism
close numpy np_all ieee ieee -- np_all prism prism
# The ieee CPython loads PRISM with the first prism module: --mode=rn must
# still reach the static kernels.
rn_np_all() { VFC_BACKENDS=$RN np_all "$@"; }
constant numpy-prism.lapack-prism:rn rn_np_all prism prism
precision numpy np_all prism ieee
if (cd "$work" && "$work/numpy-prism/bin/python" -m pytest -q -p no:cacheprovider "$here/numpy-sanity-check.py"); then
    pass "numpy-sanity-check.py (prism)"
else
    fail "numpy-sanity-check.py (prism)"
fi

echo "== libm"
clang -O2 "$here/test_libm.c" -o "$work/test_libm" -lm
libm() { fuzzy run "libm=$1" -- "$work/test_libm" "$2"; }
varies libm-prism:binary64 libm prism 64
varies libm-prism:binary32 libm prism 32
constant libm-ieee:binary64 libm ieee 64
constant libm-ieee:binary32 libm ieee 32
# Compare glibc's double functions with the rounded binary128 reference.
close libm libm ieee 64 -- libm prism 64
rn_libm() { VFC_BACKENDS=$RN libm "$@"; }
constant libm-prism:rn rn_libm prism 64
precision libm-binary64 libm prism 64
precision libm-binary32 libm prism 32
# The uninstrumented CPython calls the preloaded functions too. Many values:
# stochastic rounding moves a correctly rounded result with probability
# |error| / ulp, which is small for some inputs.
py_libm() { fuzzy run python=ieee "libm=$1" -- "$FUZZY_ROOT/python/3.12/bin/python3" -c "import math; print(*[f(i / 7).hex() for i in range(1, 50) for f in (math.sin, math.exp, math.tan)])"; }
varies libm-prism:python py_libm prism
constant libm-ieee:python py_libm ieee

# Keep every dependency ieee while testing a package's own native code. This
# catches a nominal prism wheel that accidentally contains only plain code.
echo "== SciPy, scikit-learn and the PyTorch packages"
extra_packages=(scipy sklearn torch torchaudio torchvision)
uv venv -q "$work/packages" --python "$FUZZY_ROOT/python/3.12/bin/python3"
fuzzy use --python "$work/packages" numpy=ieee scipy=ieee sklearn=ieee \
    torch=ieee torchaudio=ieee torchvision=ieee >/dev/null
probe() {
    fuzzy run python=ieee lapack=ieee libm=ieee -- \
        env OMP_NUM_THREADS=1 "$work/packages/bin/python" "$here/package-probe.py" "$1"
}
for pkg in "${extra_packages[@]}"; do
    constant "$pkg-ieee" probe "$pkg"
    probe "$pkg" >"$work/$pkg.ieee"
    fuzzy use --python "$work/packages" "$pkg=prism" >/dev/null
    varies "$pkg-prism:isolated" probe "$pkg"
    VFC_BACKENDS=$RN probe "$pkg" >"$work/$pkg.rn"
    if result=$($sys_python "$here/ulpdiff.py" "$work/$pkg.ieee" "$work/$pkg.rn" "$MAX_ULP" 2>&1); then
        pass "$pkg: prism rn vs ieee, $result"
    else
        fail "$pkg: prism rn vs ieee, $result"
    fi
    rn_probe() { VFC_BACKENDS=$RN probe "$pkg"; }
    constant "$pkg-prism:rn" rn_probe
    precision "$pkg" probe "$pkg"
    seeded_probe() { VFC_BACKENDS="$SR --seed=42" probe "$pkg"; }
    constant "$pkg-prism:seed" seeded_probe
    fuzzy use --python "$work/packages" "$pkg=ieee" >/dev/null
done
# The plain third-party codecs contain CPUID-dispatched kernels. Exercise
# them on the target CPU as well as statically auditing our own packages.
fuzzy run python=ieee lapack=ieee libm=ieee -- \
    "$work/packages/bin/python" "$here/check-image-codecs.py"
# Load every prism package into the same process, and verify that the wheel
# builds use the shared runtime rather than bundling private copies.
fuzzy use --python "$work/packages" numpy=prism scipy=prism sklearn=prism \
    torch=prism torchaudio=prism torchvision=prism >/dev/null
fuzzy run python=ieee libm=ieee -- "$work/packages/bin/python" "$here/check-runtime.py"

echo "== ISA ($level)"
$sys_python "$here/check-wheels.py" "$FUZZY_ROOT" "$work/wheels-audit"
if "$here/check-isa.sh" "$level" /usr/local/lib/libprism-static.so "$FUZZY_ROOT" "$work/wheels-audit"; then
    pass "instructions match $level"
else
    fail "instructions beyond $level"
fi

echo "== RUNPATH"
bad=$(find "$FUZZY_ROOT" "$work/wheels-audit" -type f \( -name '*.so*' -o -perm -u+x \) -print0 |
    xargs -0 -r readelf -d 2>/dev/null | grep -E '\((RUNPATH|RPATH)\)' | grep -E '/(ieee|prism)(/|:|\])' || true)
if [ -z "$bad" ]; then pass "no RUNPATH into a build directory"; else fail "RUNPATH into a build directory: $bad"; fi

echo "== fuzzy tool"
fuzzy list
for build in ieee prism; do
    fuzzy use "lapack=$build" >/dev/null
    fuzzy list >"$work/list"
    if grep -qE "^lapack +[^ ]+ +native +[^ ]+ +$build\$" "$work/list"; then
        pass "fuzzy use lapack=$build"
    else
        fail "fuzzy use lapack=$build"
    fi
done
eval "$(fuzzy env lapack=ieee)"
constant fuzzy-env "$work/test_blas"
export LD_LIBRARY_PATH=$FUZZY_ROOT/active/lib:/usr/local/lib
# A prism wheel built for another level must not install.
$sys_python "$here/wheeltool.py" marker fuzzy-level-probe 1.0 "$work/probe" >/dev/null
$sys_python "$here/wheeltool.py" retag "$work"/probe/fuzzy_level_probe-1.0-*.whl prism "$work/probe-other" \
    --requires "fuzzy-prism-runtime==0.0.0+other.level" >/dev/null
if uv pip install -q --python "$work/numpy-prism" --offline --find-links "$work/probe-other" \
    --find-links "$FUZZY_ROOT/wheels/prism" "fuzzy-level-probe==1.0+prism" 2>/dev/null; then
    fail "a prism wheel for another level installed"
else
    pass "a prism wheel for another level is rejected"
fi

rm -rf "$work"
if [ "$failures" -gt 0 ]; then
    echo "$failures check(s) failed"
    exit 1
fi
echo "all checks passed"
