#!/bin/bash
# CPU PyTorch wheel. Both flavors use the same compiler and backend options.
set -euo pipefail
. "$(dirname "$0")/../common.sh"
build=${1:?usage: build.sh <ieee|prism>}
flavor "$build"
version=${PYTORCH_VERSION:-2.5.1}
lapack=$FUZZY_ROOT/lib/lapack/${LAPACK_VERSION:-3.12.1}/ieee
requires=()
if [ "$build" = prism ]; then
    FLAGS="$FLAGS --exclude-file=$RECIPES/torch/vfc-exclude.txt"
    requires=(--requires "${PRISM_RUNTIME:?PRISM_RUNTIME must be set}")
fi
src=$(mktemp -d)
git clone -q --depth=1 --branch "v$version" --recurse-submodules --shallow-submodules \
    https://github.com/pytorch/pytorch.git "$src/torch"
uv venv -q "$src/venv" --python "$FUZZY_ROOT/python/3.12/bin/python3"
uv pip install -q --python "$src/venv" --find-links "$FUZZY_ROOT/wheels/ieee" \
    "numpy==${NUMPY_VERSION:-2.4.6}+ieee" pip 'setuptools<75' wheel 'cmake<4' ninja
uv pip install -q --python "$src/venv" -r "$src/torch/requirements.txt"
cd "$src/torch"
python3 "$RECIPES/torch/cap-isa.py" "$MARCH" .

# Seed compile checks instead of detecting what the builder can compile.
# ATen's DEFAULT kernels still use FLAGS and therefore the image's -march.
# Disabling explicit AVX kernels on v1/v2 also avoids AVX-only perfkernels.
avx=OFF avx2=OFF avx512=OFF capability=default
case $MARCH in
    x86-64-v3) avx=ON avx2=ON capability=avx2 ;;
    x86-64-v4) avx=ON avx2=ON avx512=ON capability=avx512 ;;
esac
export PATH="$src/venv/bin:$PATH"
export CFLAGS="$FLAGS" CXXFLAGS="$FLAGS -Wno-missing-template-arg-list-after-template-kw"
export LDFLAGS="$FLAGS -fopenmp"
# setup.py does not parse CMAKE_ARGS; it does pass CMAKE_* environment
# variables. Seed the checks through a top-level include before configure.
cat > "$src/isa.cmake" <<EOF
set(C_AVX_FOUND $avx CACHE BOOL "Fuzzy image ISA" FORCE)
set(CXX_AVX_FOUND $avx CACHE BOOL "Fuzzy image ISA" FORCE)
set(C_AVX2_FOUND $avx2 CACHE BOOL "Fuzzy image ISA" FORCE)
set(CXX_AVX2_FOUND $avx2 CACHE BOOL "Fuzzy image ISA" FORCE)
set(C_AVX512_FOUND $avx512 CACHE BOOL "Fuzzy image ISA" FORCE)
set(CXX_AVX512_FOUND $avx512 CACHE BOOL "Fuzzy image ISA" FORCE)
set(CAFFE2_COMPILER_SUPPORTS_AVX512_EXTENSIONS $avx512 CACHE BOOL "Fuzzy image ISA" FORCE)
set(SLEEF_DISABLE_FMA4 ON CACHE BOOL "Not part of any x86-64 level" FORCE)
set(SLEEF_DISABLE_AVX512F $([ "$avx512" = ON ] && echo OFF || echo ON) CACHE BOOL "Fuzzy image ISA" FORCE)
set(SLEEF_DISABLE_AVX2 $([ "$avx2" = ON ] && echo OFF || echo ON) CACHE BOOL "Fuzzy image ISA" FORCE)
set(SLEEF_DISABLE_AVX $([ "$avx" = ON ] && echo OFF || echo ON) CACHE BOOL "Fuzzy image ISA" FORCE)
set(SLEEF_DISABLE_SSE4 $([ "$MARCH" = x86-64 ] && echo ON || echo OFF) CACHE BOOL "Fuzzy image ISA" FORCE)
set(BLAS_LIBRARIES "$lapack/lib/libcblas.so;$lapack/lib/libblas.so" CACHE STRING "Fuzzy BLAS" FORCE)
set(BLAS_INCLUDE_DIRS "$lapack/include" CACHE STRING "Fuzzy BLAS headers" FORCE)
set(LAPACK_LIBRARIES "$lapack/lib/liblapack.so" CACHE STRING "Fuzzy LAPACK" FORCE)
EOF
export CMAKE_PROJECT_TOP_LEVEL_INCLUDES="$src/isa.cmake"
export CMAKE_POLICY_VERSION_MINIMUM=3.5 CMAKE_EXPORT_COMPILE_COMMANDS=ON
export USE_CUDA=0 USE_ROCM=0 USE_MKLDNN=0 USE_NATIVE_ARCH=0
# These optional backends build their own wider kernels or JIT uninstrumented
# machine code. Use ATen and the switchable BLAS for CPU floating-point ops.
# FBGEMM requires compiling AVX-512 even on an AVX2 target in this release.
export USE_FBGEMM=0 USE_XNNPACK=0 USE_PYTORCH_QNNPACK=0 USE_NNPACK=0
export USE_KINETO=0 USE_DISTRIBUTED=0 BUILD_TEST=0 USE_NUMPY=1 USE_LAPACK=1
export BLAS=Generic BLAS_LIBRARIES="$lapack/lib/libcblas.so;$lapack/lib/libblas.so"
export BLAS_INCLUDE_DIRS="$lapack/include" LAPACK_LIBRARIES="$lapack/lib/liblapack.so"
export MAX_JOBS=${TORCH_BUILD_JOBS:-2} ATEN_CPU_CAPABILITY=$capability
export PYTORCH_BUILD_VERSION=$version PYTORCH_BUILD_NUMBER=1
"$src/venv/bin/python" setup.py --cmake-only build
python3 "$RECIPES/torch/check-compile-isa.py" "$MARCH" build/compile_commands.json
"$src/venv/bin/python" setup.py bdist_wheel -d "$src/dist"
python3 "$RECIPES/torch/check-compile-isa.py" "$MARCH" build/compile_commands.json
python3 "$RECIPES/wheeltool.py" retag "$src"/dist/torch-*.whl "$build" "$FUZZY_ROOT/wheels/$build" \
    --drop-rpath "$FUZZY_ROOT/" "${requires[@]}"
cd /
rm -rf "$src"
register torch KIND=python "VERSION=$version" DIST=torch
