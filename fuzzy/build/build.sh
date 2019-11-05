#!/bin/bash

dockerfile=${1}
tag=${2}

docker build -t ${DOCKER_USERNAME}/fuzzy:${tag} -f fuzzy/docker/${dockerfile} fuzzy/docker/
