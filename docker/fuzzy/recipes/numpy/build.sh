#!/bin/bash
# NumPy wheel, one build:
#
#   recipes/numpy/build.sh <ieee|prism>
#
# Needs the ieee CPython and LAPACK selected (`fuzzy use python=ieee
# lapack=ieee`): both builds compile against them, since the prism builds
# have the same ABI. Writes numpy-<version>+<build> to
# $FUZZY_ROOT/wheels/<build>. The prism wheel requires $PRISM_RUNTIME, the
# marker of this image's PRISM and x86-64 level.
set -euo pipefail
. "$(dirname "$0")/../common.sh"
build=${1:?usage: build.sh <ieee|prism>}
flavor "$build"
version=${NUMPY_VERSION:-2.4.6}
lapack=$FUZZY_ROOT/lib/lapack/${LAPACK_VERSION:-3.12.1}/ieee

cflags=$FLAGS
requires=()
if [ "$build" = prism ]; then
    CC=$RECIPES/wrappers/meson-verificarlo-c
    CXX=$RECIPES/wrappers/meson-verificarlo-c++
    FC=$RECIPES/wrappers/meson-verificarlo-f
    cflags="$cflags --exclude-file=$RECIPES/numpy/vfc-exclude.txt"
    requires=(--requires "${PRISM_RUNTIME:?PRISM_RUNTIME must be set}")
fi

src=$(mktemp -d)
wget -qO- "https://github.com/numpy/numpy/releases/download/v$version/numpy-$version.tar.gz" | tar xz -C "$src"
cd "$src/numpy-$version"
# NumPy adds -ftrapping-math for Clang, which emits LLVM constrained FP
# intrinsics that Verificarlo does not rewrite. Drop it in both builds, so
# they compile the same code.
sed -i "s/^if cc_id.startswith('clang')$/if false  # fuzzy: no -ftrapping-math/" meson.build
grep -q "^if false  # fuzzy" meson.build

uv venv -q "$src/venv" --python "$FUZZY_ROOT/python/3.12/bin/python3"
uv pip install -q --python "$src/venv" pip -r requirements/build_requirements.txt
CFLAGS="$cflags" CXXFLAGS="$cflags" FFLAGS="$cflags" LDFLAGS="$cflags" \
    PKG_CONFIG_PATH="$lapack/lib/pkgconfig" PATH="$src/venv/bin:$PATH" \
    "$src/venv/bin/python" -m pip wheel --no-build-isolation --no-deps -w "$src/dist" . \
    -Csetup-args=-Dblas=blas \
    -Csetup-args=-Dlapack=lapack \
    -Csetup-args=-Dallow-noblas=false \
    -Csetup-args=-Dcpu-baseline=none \
    -Csetup-args=-Dcpu-dispatch=none

python3 "$RECIPES/wheeltool.py" retag "$src"/dist/numpy-*.whl "$build" "$FUZZY_ROOT/wheels/$build" "${requires[@]}"
cd /
rm -rf "$src"

register numpy KIND=python "VERSION=$version" DIST=numpy
