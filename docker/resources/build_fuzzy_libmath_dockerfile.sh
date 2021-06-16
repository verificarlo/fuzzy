#!/bin/bash

DOCKERFILE=Dockerfile.mcalibmath
FUZZY_IMAGE_DEFAULT=verificarlo/fuzzy:v0.4.1-lapack

generate_docker() {
    
cat > ${DOCKERFILE} <<HERE
# Base image
FROM ${1}

# Copy fuzzy environment from fuzzy image
RUN mkdir -p /opt/mca-libmath
COPY --from=${2} /opt/mca-libmath/libmath.so /opt/mca-libmath/
COPY --from=${2} /usr/local/lib/libinterflop* /usr/local/lib/

# Set environment variables
ENV VFC_BACKENDS 'libinterflop_mca.so --precision-binary32=24 --precision-binary64=53 --mode=mca'
ENV LD_PRELOAD '/opt/mca-libmath/libmath.so'
HERE
    
}

build_docker() {
    docker build -f ${DOCKERFILE} -t ${1} .
}

if [[ $# < 2 ]]
then
    echo "usage: ./build_fuzzy_libmath_dockerfile.sh <DOCKER_IMAGE> <TAG> [FUZZY_IMAGE]"
    echo "          <DOCKER_IMAGE>: Name of the base docker image to build"
    echo "          <TAG>:          Tag of the new image to build"
    echo "          [FUZZY_IMAGE]:  Name of the fuzzy image to copy from (optional)"
    exit 1
elif [[ $# == 2 ]]
then
    BASE_IMAGE=$1
    TAG=$2
    FUZZY_IMAGE=$FUZZY_IMAGE_DEFAULT
elif [[ $# == 3 ]]
then
    BASE_IMAGE=$1
    TAG=$2
    FUZZY_IMAGE=$3
fi

echo "Build fuzzy-libmath (from ${FUZZY_IMAGE}) for ${BASEIMAGE} as ${TAG}"
generate_docker $BASEIMAGE $FUZZY_IMAGE
build_docker $TAG

