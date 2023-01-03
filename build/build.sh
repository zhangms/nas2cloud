#!/bin/sh

docker kill nas2cloud
docker rm nas2cloud
docker rmi nas2cloud:v1
docker build -t nas2cloud:v1 .

docker run \
    --name nas2cloud \
    --network=nas \
    -p 7001:8080 \
    -d nas2cloud:v1
