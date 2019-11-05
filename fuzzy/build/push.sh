#!/bin/bash

tag=${1}

docker push ${DOCKER_USERNAME}/fuzzy:${tag}
