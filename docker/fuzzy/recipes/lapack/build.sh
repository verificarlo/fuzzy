#!/bin/bash
# Reference BLAS, CBLAS and LAPACK, one build:
#
#   recipes/lapack/build.sh <ieee|prism>
#
# Installs into $FUZZY_ROOT/lib/lapack/<version>/<build>. Both builds have the
# same sonames (libblas.so.3, libcblas.so.3, liblapack.so.3), so `fuzzy use
# lapack=...` switches every program and Python package linked against them.
set -euo pipefail
. "$(dirname "$0")/../common.sh"
build=${1:?usage: build.sh <ieee|prism>}
flavor "$build"
version=${LAPACK_VERSION:-3.12.1}
dir=lib/lapack/$version
prefix=$FUZZY_ROOT/$dir/$build

src=$(mktemp -d)
wget -qO- "https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v$version.tar.gz" | tar xz -C "$src"
cmake -S "$src/lapack-$version" -B "$src/build" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCBLAS=ON -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF \
    -DCMAKE_C_COMPILER="$CC" -DCMAKE_C_FLAGS="$FLAGS" \
    -DCMAKE_Fortran_COMPILER="$FC" -DCMAKE_Fortran_FLAGS="$FLAGS"
cmake --build "$src/build" -j "$(nproc)"
cmake --install "$src/build"
rm -rf "$src"

register lapack KIND=native "VERSION=$version" "DIR=$dir"
