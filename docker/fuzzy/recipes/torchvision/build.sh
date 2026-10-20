#!/bin/bash
set -euo pipefail
. "$(dirname "$0")/../common.sh"
build=${1:?usage: build.sh <ieee|prism>}
flavor "$build"
version=${TORCHVISION_VERSION:-0.20.1}
requires=()
if [ "$build" = prism ]; then
    # PyTorch probes wrappers with -v and GCC's version-query arguments.
    CXX=$RECIPES/torchvision/compiler-cxx
    FLAGS="$FLAGS --exclude-file=$RECIPES/torch/vfc-exclude.txt"
    requires=(--requires "${PRISM_RUNTIME:?PRISM_RUNTIME must be set}")
fi
src=$(mktemp -d)
git clone -q --depth=1 --branch "v$version" https://github.com/pytorch/vision.git "$src/vision"
uv venv -q "$src/venv" --python "$FUZZY_ROOT/python/3.12/bin/python3"
uv pip install -q --python "$src/venv" --find-links "$FUZZY_ROOT/wheels/ieee" \
    "torch==${PYTORCH_VERSION:-2.5.1}+ieee" "numpy==${NUMPY_VERSION:-2.4.6}+ieee" \
    pip 'setuptools<75' wheel ninja pillow
cd "$src/vision"
CFLAGS="$FLAGS" CXXFLAGS="$FLAGS" LDFLAGS="$FLAGS -fopenmp" \
    FORCE_CUDA=0 TORCHVISION_USE_FFMPEG=0 TORCHVISION_USE_VIDEO_CODEC=0 \
    MAX_JOBS=${TORCH_BUILD_JOBS:-2} BUILD_VERSION="$version" \
    PATH="$src/venv/bin:$PATH" \
    "$src/venv/bin/python" -m pip wheel --no-build-isolation --no-deps -w "$src/dist" .
python3 "$RECIPES/wheeltool.py" retag "$src"/dist/torchvision-*.whl "$build" "$FUZZY_ROOT/wheels/$build" \
    --drop-rpath "$FUZZY_ROOT/" --drop-rpath "$src/" "${requires[@]}"
cd /
rm -rf "$src"
register torchvision KIND=python "VERSION=$version" DIST=torchvision
