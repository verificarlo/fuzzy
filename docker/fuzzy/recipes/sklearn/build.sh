#!/bin/bash
# Build scikit-learn against the ieee NumPy and SciPy wheels.
set -euo pipefail
. "$(dirname "$0")/../common.sh"
build=${1:?usage: build.sh <ieee|prism>}
flavor "$build"
version=${SKLEARN_VERSION:-1.9.0}
requires=()
if [ "$build" = prism ]; then
    CC=$RECIPES/wrappers/meson-verificarlo-c
    CXX=$RECIPES/wrappers/meson-verificarlo-c++
    FC=$RECIPES/wrappers/meson-verificarlo-f
    requires=(--requires "${PRISM_RUNTIME:?PRISM_RUNTIME must be set}")
fi
src=$(mktemp -d)
wget -qO- "https://github.com/scikit-learn/scikit-learn/archive/refs/tags/$version.tar.gz" | tar xz -C "$src"
uv venv -q "$src/venv" --python "$FUZZY_ROOT/python/3.12/bin/python3"
uv pip install -q --python "$src/venv" --find-links "$FUZZY_ROOT/wheels/ieee" \
    "numpy==${NUMPY_VERSION:-2.4.6}+ieee" "scipy==${SCIPY_VERSION:-1.18.0}+ieee" \
    pip meson-python ninja cython wheel
cd "$src/scikit-learn-$version"
CFLAGS="$FLAGS" CXXFLAGS="$FLAGS" FFLAGS="$FLAGS" LDFLAGS="$FLAGS" \
    PATH="$src/venv/bin:$PATH" \
    "$src/venv/bin/python" -m pip wheel --no-build-isolation --no-deps -w "$src/dist" .
python3 "$RECIPES/wheeltool.py" retag "$src"/dist/scikit_learn-*.whl "$build" "$FUZZY_ROOT/wheels/$build" \
    --drop-rpath "$FUZZY_ROOT/" "${requires[@]}"
cd /
rm -rf "$src"
register sklearn KIND=python "VERSION=$version" DIST=scikit-learn
