#!/bin/sh

cd server
export CGO_ENABLED=0
export GOOS=linux
export GOARCH=amd64
go build -o ../build/nas2cloud
cd ..
scp -r build/* pmz@mini:/Users/pmz/NAS/nas2cloud/