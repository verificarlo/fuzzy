#!/bin/bash
# Build a SciPy wheel against the selected ieee NumPy and LAPACK.
set -euo pipefail
. "$(dirname "$0")/../common.sh"
build=${1:?usage: build.sh <ieee|prism>}
flavor "$build"
version=${SCIPY_VERSION:-1.18.0}
lapack=$FUZZY_ROOT/lib/lapack/${LAPACK_VERSION:-3.12.1}/ieee
requires=()
if [ "$build" = prism ]; then
    CC=$RECIPES/wrappers/meson-verificarlo-c
    CXX=$RECIPES/wrappers/meson-verificarlo-c++
    FC=$RECIPES/wrappers/meson-verificarlo-f
    requires=(--requires "${PRISM_RUNTIME:?PRISM_RUNTIME must be set}")
fi
src=$(mktemp -d)
git clone -q --depth=1 --branch "v$version" --recurse-submodules --shallow-submodules \
    https://github.com/scipy/scipy.git "$src/scipy"
uv venv -q "$src/venv" --python "$FUZZY_ROOT/python/3.12/bin/python3"
uv pip install -q --python "$src/venv" --find-links "$FUZZY_ROOT/wheels/ieee" \
    "numpy==${NUMPY_VERSION:-2.4.6}+ieee" pip meson-python ninja cython pythran pybind11 packaging wheel
cd "$src/scipy"
# Invoke f2py through the build interpreter; its script may inherit a stale
# interpreter path from the wheel it was installed from.
sed -i "s/f2py_version = run_command(\[f2py, '-v'\], check: true).stdout().strip()/f2py_version = run_command(py3, ['-I', '-m', 'numpy.f2py', '-v'], check: true).stdout().strip()/g" scipy/meson.build
CFLAGS="$FLAGS" CXXFLAGS="$FLAGS" FFLAGS="$FLAGS" LDFLAGS="$FLAGS" \
    PKG_CONFIG_PATH="$lapack/lib/pkgconfig" PATH="$src/venv/bin:$PATH" \
    "$src/venv/bin/python" -m pip wheel --no-build-isolation --no-deps -w "$src/dist" . \
    -Csetup-args=-Dblas=blas -Csetup-args=-Dlapack=lapack
python3 "$RECIPES/wheeltool.py" retag "$src"/dist/scipy-*.whl "$build" "$FUZZY_ROOT/wheels/$build" \
    --drop-rpath "$FUZZY_ROOT/" "${requires[@]}"
cd /
rm -rf "$src"
register scipy KIND=python "VERSION=$version" DIST=scipy
