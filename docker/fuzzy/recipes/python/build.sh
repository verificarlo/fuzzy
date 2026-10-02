#!/bin/bash
# CPython, one build:
#
#   recipes/python/build.sh <ieee|prism>
#
# Both builds are configured for the same prefix, $FUZZY_ROOT/python/<x.y>,
# with --enable-shared, so the floating-point code lives in
# libpython<x.y>.so.1.0 and in the extension modules of lib-dynload (math,
# cmath, _decimal, _statistics, ...). Those two parts of each build go to
# $FUZZY_ROOT/lib/python/<x.y>/<build>/{lib,lib-dynload}; everything else (the
# interpreter executable, the pure-Python standard library, headers,
# sysconfig) comes from the ieee build and is shared. In the prefix,
# libpython and lib-dynload are symlinks into $FUZZY_ROOT/active, so
# `fuzzy use python=...` switches them for every environment created from
# this interpreter.
set -euo pipefail
. "$(dirname "$0")/../common.sh"
build=${1:?usage: build.sh <ieee|prism>}
flavor "$build"
version=${PYTHON_VERSION:-3.12.13}
short=${version%.*}
prefix=$FUZZY_ROOT/python/$short
out=$FUZZY_ROOT/lib/python/$short/$build

cflags=$FLAGS
if [ "$build" = prism ]; then
    cflags="$cflags --exclude-file=$RECIPES/python/vfc-exclude.txt"
fi

src=$(mktemp -d)
wget -qO- "https://www.python.org/ftp/python/$version/Python-$version.tar.xz" | tar xJ -C "$src"
cd "$src/Python-$version"
./configure --prefix="$prefix" --enable-shared --without-ensurepip \
    CC="$CC" CFLAGS="$cflags" \
    LDFLAGS="$cflags -Wl,-rpath,$FUZZY_ROOT/active/lib"
make -j "$(nproc)"

# The prism build only contributes libpython and lib-dynload: stage it.
dest=
if [ "$build" = prism ]; then dest=$src/stage; fi
make install DESTDIR="$dest"

mkdir -p "$out/lib"
mv "$dest$prefix/lib/libpython$short.so.1.0" "$out/lib/"
mv "$dest$prefix/lib/python$short/lib-dynload" "$out/lib-dynload"
if [ "$build" = ieee ]; then
    ln -sfn "$FUZZY_ROOT/active/lib/libpython$short.so.1.0" "$prefix/lib/libpython$short.so.1.0"
    ln -sfn "$FUZZY_ROOT/active/dynload" "$prefix/lib/python$short/lib-dynload"
fi
cd /
rm -rf "$src"

register python KIND=interpreter "VERSION=$version" "DIR=lib/python/$short"
