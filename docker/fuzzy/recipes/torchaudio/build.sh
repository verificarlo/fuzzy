#!/bin/bash
set -euo pipefail
. "$(dirname "$0")/../common.sh"
build=${1:?usage: build.sh <ieee|prism>}
flavor "$build"
version=${TORCHAUDIO_VERSION:-2.5.1}
requires=()
if [ "$build" = prism ]; then
    FLAGS="$FLAGS --exclude-file=$RECIPES/torch/vfc-exclude.txt"
    requires=(--requires "${PRISM_RUNTIME:?PRISM_RUNTIME must be set}")
fi
src=$(mktemp -d)
git clone -q --depth=1 --branch "v$version" --recurse-submodules --shallow-submodules \
    https://github.com/pytorch/audio.git "$src/audio"
uv venv -q "$src/venv" --python "$FUZZY_ROOT/python/3.12/bin/python3"
uv pip install -q --python "$src/venv" --find-links "$FUZZY_ROOT/wheels/ieee" \
    "torch==${PYTORCH_VERSION:-2.5.1}+ieee" pip 'setuptools<75' wheel 'cmake<4' ninja
cd "$src/audio"
CFLAGS="$FLAGS" CXXFLAGS="$FLAGS" LDFLAGS="$FLAGS -fopenmp" \
    USE_CUDA=0 USE_ROCM=0 BUILD_SOX=0 USE_FFMPEG=0 BUILD_KALDI=1 \
    BUILD_RNNT=1 USE_OPENMP=1 MAX_JOBS=${TORCH_BUILD_JOBS:-2} \
    BUILD_VERSION="$version" PATH="$src/venv/bin:$PATH" \
    "$src/venv/bin/python" -m pip wheel --no-build-isolation --no-deps -w "$src/dist" .
python3 "$RECIPES/wheeltool.py" retag "$src"/dist/torchaudio-*.whl "$build" "$FUZZY_ROOT/wheels/$build" \
    --drop-rpath "$FUZZY_ROOT/" --drop-rpath "$src/" "${requires[@]}"
cd /
rm -rf "$src"
register torchaudio KIND=python "VERSION=$version" DIST=torchaudio
