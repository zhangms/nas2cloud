#!/bin/sh

echo "clean..."
docker kill nas2cloud
docker rm nas2cloud
docker rmi nas2cloud:v1

echo "install..."
docker build -t nas2cloud:v1 .

echo "run nas2cloud"
docker run \
    --name nas2cloud \
    --network=nas \
    --cpus=2 \
    -p 7001:8080 \
    -v /Volumes/Y/Mount:/nas2cloud/Volumes/Family \
    -v /Users/ZMS/Thumb:/nas2cloud/thumb \
    --restart=always \
    -d nas2cloud:v1
