# verificarlo/fuzzy:<verificarlo>-<level>: one image per x86-64 level, with
# every package built twice, with Verificarlo's PRISM backend (prism) and
# without instrumentation (ieee). `fuzzy use PKG=BUILD` picks a build at run
# time; see docker/fuzzy/README.md. build.sh passes the arguments below.
# Build context: the repository root.
#
# Each (package, build) pair is its own stage, so BuildKit and buildah build
# independent ones in parallel and cache them separately. The wheels of both
# builds compile against the ieee CPython and LAPACK (stage build-env): the
# prism builds have the same ABI.
#
# Requires BuildKit (docker) or buildah (podman) for COPY --from of stages.

# The level's Verificarlo image: PRISM's static kernels compiled for MARCH.
ARG BASE=localhost/verificarlo/verificarlo:v2.7.0-avx2
ARG UV_IMAGE=ghcr.io/astral-sh/uv:0.12.21

FROM ${UV_IMAGE} AS uv

FROM ${BASE} AS base
ARG MARCH=x86-64-v3
ENV MARCH=${MARCH} \
    FUZZY_ROOT=/opt/fuzzy \
    LD_LIBRARY_PATH=/opt/fuzzy/active/lib:/usr/local/lib \
    VFC_BACKENDS="libinterflop_prism.so --mode=rn" \
    VFC_BACKENDS_LOGGER=False \
    VFC_BACKENDS_SILENT_LOAD=True \
    UV_PYTHON_DOWNLOADS=never \
    UV_NO_CACHE=1
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends -qq \
    wget xz-utils cmake pkgconf patchelf ninja-build libjpeg-dev libpng-dev \
    libssl-dev zlib1g-dev libbz2-dev liblzma-dev libreadline-dev \
    libsqlite3-dev libncurses-dev libffi-dev libgdbm-dev uuid-dev && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /opt/fuzzy/active
COPY --from=uv /uv /uvx /usr/local/bin/
COPY docker/fuzzy/recipes/common.sh /opt/fuzzy-src/recipes/
COPY docker/fuzzy/recipes/wrappers/ /opt/fuzzy-src/recipes/wrappers/
RUN case "$MARCH" in x86-64|x86-64-v2) bits=128;; x86-64-v3) bits=256;; x86-64-v4) bits=512;; esac && \
    clang++ -shared -fPIC -O2 -DFUZZY_VECTOR_BITS=$bits \
    $(llvm-config-20 --cxxflags) /opt/fuzzy-src/recipes/wrappers/legalize-prism.cpp \
    -o /opt/fuzzy-src/recipes/wrappers/legalize-prism.so \
    $(llvm-config-20 --ldflags --libs core passes) && \
    python3 /opt/fuzzy-src/recipes/wrappers/install-legalizer.py /usr/local/bin/verificarlo

# Each stage copies only its own recipe, so that editing one recipe rebuilds
# only that package.
FROM base AS lapack
COPY docker/fuzzy/recipes/lapack/ /opt/fuzzy-src/recipes/lapack/

FROM lapack AS lapack-ieee
RUN /opt/fuzzy-src/recipes/lapack/build.sh ieee

FROM lapack AS lapack-prism
RUN /opt/fuzzy-src/recipes/lapack/build.sh prism

FROM base AS python
COPY docker/fuzzy/recipes/python/ /opt/fuzzy-src/recipes/python/
COPY docker/resources/python-vfc-exclude.txt /opt/fuzzy-src/recipes/python/vfc-exclude.txt

FROM python AS python-ieee
RUN /opt/fuzzy-src/recipes/python/build.sh ieee

FROM python AS python-prism
RUN /opt/fuzzy-src/recipes/python/build.sh prism

FROM base AS libm
COPY docker/fuzzy/recipes/libm/ /opt/fuzzy-src/recipes/libm/

FROM libm AS libm-ieee
RUN /opt/fuzzy-src/recipes/libm/build.sh ieee

FROM libm AS libm-prism
RUN /opt/fuzzy-src/recipes/libm/build.sh prism

# The ieee CPython and LAPACK, selected, to build the wheels of both builds.
FROM base AS build-env
COPY docker/fuzzy/bin/fuzzy /usr/local/bin/fuzzy
COPY --from=lapack-ieee /opt/fuzzy/ /opt/fuzzy/
COPY --from=python-ieee /opt/fuzzy/ /opt/fuzzy/
RUN fuzzy use lapack=ieee python=ieee

FROM build-env AS numpy
COPY docker/fuzzy/recipes/wheeltool.py /opt/fuzzy-src/recipes/
COPY docker/fuzzy/recipes/numpy/ /opt/fuzzy-src/recipes/numpy/
COPY docker/resources/numpy-vfc-exclude.txt /opt/fuzzy-src/recipes/numpy/vfc-exclude.txt

FROM numpy AS numpy-ieee
RUN /opt/fuzzy-src/recipes/numpy/build.sh ieee

FROM numpy AS numpy-prism
ARG PRISM_RUNTIME_VERSION=0.0.12+x86.64.v3
RUN PRISM_RUNTIME="fuzzy-prism-runtime==${PRISM_RUNTIME_VERSION}" \
    /opt/fuzzy-src/recipes/numpy/build.sh prism

FROM build-env AS scipy
COPY docker/fuzzy/recipes/wheeltool.py /opt/fuzzy-src/recipes/
COPY docker/fuzzy/recipes/scipy/ /opt/fuzzy-src/recipes/scipy/
COPY --from=numpy-ieee /opt/fuzzy/wheels/ /opt/fuzzy/wheels/

FROM scipy AS scipy-ieee
RUN /opt/fuzzy-src/recipes/scipy/build.sh ieee

FROM scipy AS scipy-prism
ARG PRISM_RUNTIME_VERSION=0.0.12+x86.64.v3
RUN PRISM_RUNTIME="fuzzy-prism-runtime==${PRISM_RUNTIME_VERSION}" \
    /opt/fuzzy-src/recipes/scipy/build.sh prism

FROM scipy AS sklearn
COPY docker/fuzzy/recipes/sklearn/ /opt/fuzzy-src/recipes/sklearn/
COPY --from=scipy-ieee /opt/fuzzy/wheels/ /opt/fuzzy/wheels/

FROM sklearn AS sklearn-ieee
RUN /opt/fuzzy-src/recipes/sklearn/build.sh ieee

FROM sklearn AS sklearn-prism
ARG PRISM_RUNTIME_VERSION=0.0.12+x86.64.v3
RUN PRISM_RUNTIME="fuzzy-prism-runtime==${PRISM_RUNTIME_VERSION}" \
    /opt/fuzzy-src/recipes/sklearn/build.sh prism

FROM scipy AS torch
ARG TORCH_BUILD_JOBS=2
ENV TORCH_BUILD_JOBS=${TORCH_BUILD_JOBS}
COPY docker/fuzzy/recipes/torch/ /opt/fuzzy-src/recipes/torch/

FROM torch AS torch-ieee
RUN /opt/fuzzy-src/recipes/torch/build.sh ieee

FROM torch AS torch-prism
ARG PRISM_RUNTIME_VERSION=0.0.12+x86.64.v3
RUN PRISM_RUNTIME="fuzzy-prism-runtime==${PRISM_RUNTIME_VERSION}" \
    /opt/fuzzy-src/recipes/torch/build.sh prism

FROM torch AS torch-extension
COPY --from=torch-ieee /opt/fuzzy/wheels/ /opt/fuzzy/wheels/

FROM torch-extension AS torchaudio
COPY docker/fuzzy/recipes/torchaudio/ /opt/fuzzy-src/recipes/torchaudio/

FROM torchaudio AS torchaudio-ieee
RUN /opt/fuzzy-src/recipes/torchaudio/build.sh ieee

FROM torchaudio AS torchaudio-prism
ARG PRISM_RUNTIME_VERSION=0.0.12+x86.64.v3
RUN PRISM_RUNTIME="fuzzy-prism-runtime==${PRISM_RUNTIME_VERSION}" \
    /opt/fuzzy-src/recipes/torchaudio/build.sh prism

FROM torch-extension AS torchvision
COPY docker/fuzzy/recipes/torchvision/ /opt/fuzzy-src/recipes/torchvision/

FROM torchvision AS torchvision-ieee
RUN /opt/fuzzy-src/recipes/torchvision/build.sh ieee

FROM torchvision AS torchvision-prism
ARG PRISM_RUNTIME_VERSION=0.0.12+x86.64.v3
RUN PRISM_RUNTIME="fuzzy-prism-runtime==${PRISM_RUNTIME_VERSION}" \
    /opt/fuzzy-src/recipes/torchvision/build.sh prism

FROM base AS prism-runtime
ARG PRISM_RUNTIME_VERSION=0.0.12+x86.64.v3
COPY docker/fuzzy/recipes/wheeltool.py /opt/fuzzy-src/recipes/
RUN python3 /opt/fuzzy-src/recipes/wheeltool.py marker \
    fuzzy-prism-runtime "${PRISM_RUNTIME_VERSION}" /opt/fuzzy/wheels/prism

FROM ${BASE} AS final
ARG MARCH=x86-64-v3
ARG LEVEL=x86-64-v3
ARG VERIFICARLO_VERSION=v2.7.0
LABEL org.verificarlo.fuzzy.level=${LEVEL} \
      org.verificarlo.fuzzy.march=${MARCH} \
      org.verificarlo.version=${VERIFICARLO_VERSION}
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends -qq \
    libssl3t64 zlib1g libbz2-1.0 liblzma5 libreadline8t64 libsqlite3-0 \
    libncursesw6 libffi8 libgdbm6t64 libuuid1 libjpeg-turbo8 libpng16-16t64 && \
    rm -rf /var/lib/apt/lists/*
COPY --from=uv /uv /uvx /usr/local/bin/
COPY docker/fuzzy/bin/fuzzy /usr/local/bin/fuzzy
COPY --from=lapack-ieee /opt/fuzzy/ /opt/fuzzy/
COPY --from=lapack-prism /opt/fuzzy/ /opt/fuzzy/
COPY --from=python-ieee /opt/fuzzy/ /opt/fuzzy/
COPY --from=python-prism /opt/fuzzy/ /opt/fuzzy/
COPY --from=libm-ieee /opt/fuzzy/ /opt/fuzzy/
COPY --from=libm-prism /opt/fuzzy/ /opt/fuzzy/
# libfuzzy-libm.so is preloaded by name, from the selected libm build in
# /opt/fuzzy/active/lib. The empty ieee library is also installed system-wide,
# so that the preload never fails when LD_LIBRARY_PATH does not include it.
COPY --from=libm-ieee /opt/fuzzy/lib/libm/quad/ieee/lib/libfuzzy-libm.so /usr/local/lib/
RUN ldconfig
COPY --from=numpy-ieee /opt/fuzzy/wheels/ /opt/fuzzy/wheels/
COPY --from=numpy-ieee /opt/fuzzy/registry/numpy.env /opt/fuzzy/registry/
COPY --from=numpy-prism /opt/fuzzy/wheels/ /opt/fuzzy/wheels/
COPY --from=scipy-ieee /opt/fuzzy/wheels/ /opt/fuzzy/wheels/
COPY --from=scipy-ieee /opt/fuzzy/registry/scipy.env /opt/fuzzy/registry/
COPY --from=scipy-prism /opt/fuzzy/wheels/ /opt/fuzzy/wheels/
COPY --from=sklearn-ieee /opt/fuzzy/wheels/ /opt/fuzzy/wheels/
COPY --from=sklearn-ieee /opt/fuzzy/registry/sklearn.env /opt/fuzzy/registry/
COPY --from=sklearn-prism /opt/fuzzy/wheels/ /opt/fuzzy/wheels/
COPY --from=torch-ieee /opt/fuzzy/wheels/ /opt/fuzzy/wheels/
COPY --from=torch-ieee /opt/fuzzy/registry/torch.env /opt/fuzzy/registry/
COPY --from=torch-prism /opt/fuzzy/wheels/ /opt/fuzzy/wheels/
COPY --from=torchaudio-ieee /opt/fuzzy/wheels/ /opt/fuzzy/wheels/
COPY --from=torchaudio-ieee /opt/fuzzy/registry/torchaudio.env /opt/fuzzy/registry/
COPY --from=torchaudio-prism /opt/fuzzy/wheels/ /opt/fuzzy/wheels/
COPY --from=torchvision-ieee /opt/fuzzy/wheels/ /opt/fuzzy/wheels/
COPY --from=torchvision-ieee /opt/fuzzy/registry/torchvision.env /opt/fuzzy/registry/
COPY --from=torchvision-prism /opt/fuzzy/wheels/ /opt/fuzzy/wheels/
COPY --from=prism-runtime /opt/fuzzy/wheels/ /opt/fuzzy/wheels/
ENV FUZZY_ROOT=/opt/fuzzy \
    LD_LIBRARY_PATH=/opt/fuzzy/active/lib:/usr/local/lib \
    LD_PRELOAD=libfuzzy-libm.so \
    PYTHONPATH= \
    VFC_BACKENDS="libinterflop_prism.so --mode=sr" \
    VFC_BACKENDS_LOGGER=False \
    VFC_BACKENDS_SILENT_LOAD=True \
    UV_PYTHON_DOWNLOADS=never \
    VIRTUAL_ENV=/opt/fuzzy/venv \
    PATH=/opt/fuzzy/venv/bin:${PATH}
# Verificarlo's driver keeps running on the system Python, not on whichever
# CPython build is selected. libm switches to prism last: until then the
# preload is the empty ieee library, from /usr/local/lib.
RUN sed -i '1s|^#!.*python3$|#!/usr/bin/python3|' /usr/local/bin/verificarlo && \
    fuzzy use lapack=prism python=prism && \
    uv venv --seed --no-cache /opt/fuzzy/venv --python /opt/fuzzy/python/3.12/bin/python3 && \
    UV_NO_CACHE=1 fuzzy use numpy=prism scipy=prism sklearn=prism torch=prism torchaudio=prism torchvision=prism && \
    fuzzy use libm=prism && \
    fuzzy list
WORKDIR /workdir
CMD ["/bin/bash"]

FROM final AS test
ARG LEVEL=x86-64-v3
ARG VERIFICARLO_VERSION=v2.7.0
COPY docker/fuzzy/tests/ /opt/fuzzy-tests/
COPY docker/fuzzy/recipes/wheeltool.py /opt/fuzzy-tests/
COPY docker/fuzzy/recipes/wrappers/ /opt/fuzzy-tests/wrappers/
COPY docker/resources/lapack/test_blas.c docker/resources/numpy-sanity-check.py /opt/fuzzy-tests/
RUN FUZZY_VERIFICARLO_VERSION="${VERIFICARLO_VERSION}" /opt/fuzzy-tests/run.sh "${LEVEL}"
