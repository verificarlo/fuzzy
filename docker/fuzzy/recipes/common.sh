# Sourced by every recipe: `flavor <ieee|prism>` sets the compilers and flags
# of one build. Both builds use the same LLVM front ends (verificarlo-c runs
# clang, then the PRISM pass, then clang again, with the caller's flags), the
# same -march and the same options, so the only difference between them is
# PRISM's rounding.
#
# Environment: MARCH (the image's x86-64 level, e.g. x86-64-v3) and
# FUZZY_ROOT (default /opt/fuzzy).

: "${MARCH:?MARCH must be set, e.g. x86-64-v3}"
FUZZY_ROOT=${FUZZY_ROOT:-/opt/fuzzy}
RECIPES=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

flavor() {
    case $1 in
    ieee)
        CC=clang CXX=clang++ FC=flang
        FLAGS="-march=$MARCH"
        ;;
    prism)
        CC=verificarlo-c CXX=verificarlo-c++ FC=verificarlo-f
        FLAGS="--prism-backend=sr --prism-backend-dispatch=static -march=$MARCH --inst-fma"
        ;;
    *)
        echo "unknown build: $1 (ieee or prism)" >&2
        return 2
        ;;
    esac
    export CC CXX FC FLAGS
}

# register NAME KEY=VALUE...: write $FUZZY_ROOT/registry/NAME.env, the
# manifest the fuzzy tool reads. Both builds of a package write the same file.
register() {
    local name=$1
    shift
    mkdir -p "$FUZZY_ROOT/registry"
    printf '%s\n' "$@" "BUILDS=\"ieee prism\"" >"$FUZZY_ROOT/registry/$name.env"
}
