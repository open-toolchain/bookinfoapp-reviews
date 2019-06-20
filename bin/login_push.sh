#!/bin/bash

docker version
docker login -u kalantar -p xaBZj57x index.docker.io/v1/
cat ~/.docker/config.json || true
echo $1
docker push ${1}