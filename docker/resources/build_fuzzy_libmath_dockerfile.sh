#!/bin/bash

DOCKERFILE=Dockerfile.mcalibmath

generate_docker() {
    
cat > ${DOCKERFILE} <<HERE
# Multistage build

# Not the base image, will be used to copy stuff from
FROM verificarlo/fuzzy:v0.4.1-lapack as fuzzy

# Base image
FROM ${1}

# Copy fuzzy environment from fuzzy image
RUN mkdir -p /opt/mca-libmath
COPY --from=fuzzy /opt/mca-libmath/libmath.so /opt/mca-libmath/
COPY --from=fuzzy /usr/local/lib/libinterflop* /usr/local/lib/

# Set environment variables
ENV VFC_BACKENDS 'libinterflop_mca.so --precision-binary32=24 --precision-binary64=53 --mode=mca'
ENV LD_PRELOAD '/opt/mca-libmath/libmath.so'
HERE
    
}

build_docker() {
    docker build -f ${DOCKERFILE} -t ${1} .
}

if [[ $# < 2 ]]; then
    echo "usage: ./build_fuzzy_libmath_dockerfile <DOCKER_IMAGE> <TAG>"
    exit 1
else
    BASEIMAGE=$1
    TAG=$2
fi

echo "Build fuzzy-libmath for ${BASEIMAGE} as ${TAG}"
generate_docker $BASEIMAGE
build_docker $TAG

