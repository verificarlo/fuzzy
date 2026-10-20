#!/bin/bash
# The C library's math functions, one build:
#
#   recipes/libm/build.sh <ieee|prism>
#
# Installs libfuzzy-libm.so into $FUZZY_ROOT/lib/libm/quad/<build>/lib. The
# image preloads it by name (LD_PRELOAD=libfuzzy-libm.so), so the dynamic
# loader finds it through LD_LIBRARY_PATH like the other native packages, and
# `fuzzy use/run/env libm=...` switch it the same way.
#   prism  fuzzy-libm.c: sin, exp, log, pow... computed in binary128 and
#          rounded by PRISM (INTERFLOP_ROUND_DW_ID).
#   ieee   an empty library: the functions come from glibc's libm.
#
# The prism library is linked by verificarlo-c, for interflop_call and the
# backend loader, but none of its code is instrumented: its binary128
# arithmetic must stay exact until the final rounding.
set -euo pipefail
. "$(dirname "$0")/../common.sh"
build=${1:?usage: build.sh <ieee|prism>}
flavor "$build"
dir=lib/libm/quad
prefix=$FUZZY_ROOT/$dir/$build
mkdir -p "$prefix/lib"

case $build in
ieee)
    echo '/* empty: libm=ieee uses glibc */' >"$prefix/lib/empty.c"
    clang -shared -fPIC -o "$prefix/lib/libfuzzy-libm.so" "$prefix/lib/empty.c"
    rm "$prefix/lib/empty.c"
    ;;
prism)
    src=$(mktemp -d)
    echo '* *' >"$src/exclude-all.txt"
    # quadmath.h is in GCC's own include directory, which clang does not search.
    # shellcheck disable=SC2086
    $CC $FLAGS -O2 -fPIC -shared --exclude-file="$src/exclude-all.txt" \
        -isystem "$(gcc -print-file-name=include)" \
        -o "$prefix/lib/libfuzzy-libm.so" "$RECIPES/libm/fuzzy-libm.c" -lquadmath
    rm -rf "$src"
    ;;
esac

register libm KIND=native VERSION=quad "DIR=$dir"
