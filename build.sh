#!/bin/bash

dockerfile=${1}
tag=${2}

cd docker
docker build -t ${DOCKER_USERNAME}/fuzzy:${tag} -f ${dockerfile} .
