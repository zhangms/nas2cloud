#!/bin/sh

echo "build server..."
export CGO_ENABLED=0
export GOOS=linux
export GOARCH=amd64
go build -o release/docker/nas2cloud

