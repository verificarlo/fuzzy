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
ARG BASE=localhost/verificarlo/verificarlo:v2.6.0-avx2
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
    wget xz-utils cmake pkgconf patchelf \
    libssl-dev zlib1g-dev libbz2-dev liblzma-dev libreadline-dev \
    libsqlite3-dev libncurses-dev libffi-dev libgdbm-dev uuid-dev && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /opt/fuzzy/active
COPY --from=uv /uv /uvx /usr/local/bin/
COPY docker/fuzzy/recipes/common.sh /opt/fuzzy-src/recipes/
COPY docker/fuzzy/recipes/wrappers/ /opt/fuzzy-src/recipes/wrappers/

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
ARG PRISM_RUNTIME_VERSION=0.0.8+x86.64.v3
RUN PRISM_RUNTIME="fuzzy-prism-runtime==${PRISM_RUNTIME_VERSION}" \
    /opt/fuzzy-src/recipes/numpy/build.sh prism

FROM base AS prism-runtime
ARG PRISM_RUNTIME_VERSION=0.0.8+x86.64.v3
COPY docker/fuzzy/recipes/wheeltool.py /opt/fuzzy-src/recipes/
RUN python3 /opt/fuzzy-src/recipes/wheeltool.py marker \
    fuzzy-prism-runtime "${PRISM_RUNTIME_VERSION}" /opt/fuzzy/wheels/prism

FROM ${BASE} AS final
ARG MARCH=x86-64-v3
ARG LEVEL=x86-64-v3
ARG VERIFICARLO_VERSION=v2.6.0
LABEL org.verificarlo.fuzzy.level=${LEVEL} \
      org.verificarlo.fuzzy.march=${MARCH} \
      org.verificarlo.version=${VERIFICARLO_VERSION}
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends -qq \
    libssl3t64 zlib1g libbz2-1.0 liblzma5 libreadline8t64 libsqlite3-0 \
    libncursesw6 libffi8 libgdbm6t64 libuuid1 patchelf && \
    rm -rf /var/lib/apt/lists/*
# PRISM's run-time options (--mode, --precision-*, --seed) reach the
# static kernels only when libprism-static.so is in the global symbol scope.
# A program not built by verificarlo-c, such as the ieee CPython, would
# otherwise load it with dlopen, privately, when it imports the first prism
# module, and the kernels would keep their defaults. Preload it, for every
# process; the file is part of the image, so this holds under Apptainer too.
COPY docker/fuzzy/recipes/add-hwy-needed.sh /opt/fuzzy-src/
RUN /opt/fuzzy-src/add-hwy-needed.sh && \
    echo /usr/local/lib/libprism-static.so >> /etc/ld.so.preload
COPY --from=uv /uv /uvx /usr/local/bin/
COPY docker/fuzzy/bin/fuzzy /usr/local/bin/fuzzy
COPY --from=lapack-ieee /opt/fuzzy/ /opt/fuzzy/
COPY --from=lapack-prism /opt/fuzzy/ /opt/fuzzy/
COPY --from=python-ieee /opt/fuzzy/ /opt/fuzzy/
COPY --from=python-prism /opt/fuzzy/ /opt/fuzzy/
COPY --from=numpy-ieee /opt/fuzzy/wheels/ /opt/fuzzy/wheels/
COPY --from=numpy-ieee /opt/fuzzy/registry/numpy.env /opt/fuzzy/registry/
COPY --from=numpy-prism /opt/fuzzy/wheels/ /opt/fuzzy/wheels/
COPY --from=prism-runtime /opt/fuzzy/wheels/ /opt/fuzzy/wheels/
ENV FUZZY_ROOT=/opt/fuzzy \
    LD_LIBRARY_PATH=/opt/fuzzy/active/lib:/usr/local/lib \
    PYTHONPATH= \
    VFC_BACKENDS="libinterflop_prism.so --mode=sr" \
    VFC_BACKENDS_LOGGER=False \
    VFC_BACKENDS_SILENT_LOAD=True \
    UV_PYTHON_DOWNLOADS=never \
    VIRTUAL_ENV=/opt/fuzzy/venv \
    PATH=/opt/fuzzy/venv/bin:${PATH}
# Verificarlo's driver keeps running on the system Python, not on whichever
# CPython build is selected.
RUN sed -i '1s|^#!.*python3$|#!/usr/bin/python3|' /usr/local/bin/verificarlo && \
    fuzzy use lapack=prism python=prism && \
    uv venv --seed --no-cache /opt/fuzzy/venv --python /opt/fuzzy/python/3.12/bin/python3 && \
    UV_NO_CACHE=1 fuzzy use numpy=prism && \
    fuzzy list
WORKDIR /workdir
CMD ["/bin/bash"]

FROM final AS test
ARG LEVEL=x86-64-v3
COPY docker/fuzzy/tests/ /opt/fuzzy-tests/
COPY docker/fuzzy/recipes/wheeltool.py /opt/fuzzy-tests/
COPY docker/resources/lapack/test_blas.c docker/resources/numpy-sanity-check.py /opt/fuzzy-tests/
RUN /opt/fuzzy-tests/run.sh "${LEVEL}"
