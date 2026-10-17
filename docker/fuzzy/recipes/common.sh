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
    # PRISM exports power-of-two vectors through 32 lanes. LLVM 20 can form
    # unsupported SLP packs in LAPACK. Keep normal loop vectorization here;
    # ATen's DEFAULT kernels need a separate limit in torch/cap-isa.py.
    # Build systems also pass these compile options to link-only probes.
    # Ignore unused command-line options there, including under -Werror.
    local vector_flags='-mllvm -slp-max-vf=32 -mllvm -slp-vectorize-non-power-of-2=false -Qunused-arguments'
    case $1 in
    ieee)
        CC=clang CXX=clang++ FC=flang
        FLAGS="-march=$MARCH $vector_flags"
        ;;
    prism)
        CC=$RECIPES/wrappers/prism-verificarlo-c
        CXX=$RECIPES/wrappers/prism-verificarlo-c++
        FC=$RECIPES/wrappers/prism-verificarlo-f
        FLAGS="--prism-backend=sr --prism-backend-dispatch=static --prism-backend-strict-abi -march=$MARCH --inst-fma $vector_flags"
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
