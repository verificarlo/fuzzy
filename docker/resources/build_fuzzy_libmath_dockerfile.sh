#!/bin/bash

DOCKERFILE=Dockerfile.mcalibmath
FUZZY_IMAGE_DEFAULT=verificarlo/fuzzy:v0.9.1-lapack

generate_docker() {

    cat >${DOCKERFILE} <<HERE
# Base image
FROM ${1}

RUN mkdir -p /opt/mca-libmath/{fast,standard,quad,mpfr} 
COPY --from=${2} /opt/mca-libmath/set-fuzzy-libmath.py /usr/local/bin/set-fuzzy-libmath
COPY --from=${2} /opt/mca-libmath/fast/libmath.so /opt/mca-libmath/fast/libmath.so
COPY --from=${2} /opt/mca-libmath/standard/libmath.so /opt/mca-libmath/standard/libmath.so
COPY --from=${2} /opt/mca-libmath/quad/libmath.so /opt/mca-libmath/quad/libmath.so
COPY --from=${2} /opt/mca-libmath/mpfr/libmath.so /opt/mca-libmath/mpfr/libmath.so
COPY --from=${2} /usr/local/lib/libinterflop* /usr/local/lib/

# If you will also want to recompile more libraries with verificarlo, add these lines
COPY --from=${2} /usr/local/bin/verificarlo* /usr/local/bin/
COPY --from=${2} /usr/local/include/* /usr/local/include/

# Preloading the instrumented shared library
ARG FUZZY_LIBMATH_VERSION=standard
RUN set-fuzzy-libmath --version=${FUZZY_LIBMATH_VERSION}

ENV VFC_BACKENDS 'libinterflop_mca.so --precision-binary32=24 --precision-binary64=53 --mode=rr'
HERE

}

build_docker() {
    docker build -f ${DOCKERFILE} -t ${1} .
}

if [[ $# < 2 ]]; then
    echo "usage: ./build_fuzzy_libmath_dockerfile.sh <DOCKER_IMAGE> <TAG> [FUZZY_IMAGE]"
    echo "          <DOCKER_IMAGE>: Name of the base docker image to build"
    echo "          <TAG>:          Tag of the new image to build"
    echo "          [FUZZY_IMAGE]:  Name of the fuzzy image to copy from (optional)"
    echo "                          Requires a fuzzy version >= 0.9.1"
    exit 1
elif [[ $# == 2 ]]; then
    BASE_IMAGE=$1
    TAG=$2
    FUZZY_IMAGE=$FUZZY_IMAGE_DEFAULT
elif [[ $# == 3 ]]; then
    BASE_IMAGE=$1
    TAG=$2
    FUZZY_IMAGE=$3
fi

echo "Build fuzzy-libmath (from ${FUZZY_IMAGE}) for ${BASEIMAGE} as ${TAG}"
generate_docker $BASEIMAGE $FUZZY_IMAGE
build_docker $TAG
