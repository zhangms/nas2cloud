#!/bin/sh

echo "build server..."
cd server
export CGO_ENABLED=0
export GOOS=linux
export GOARCH=amd64
go build -o ../release/docker/nas2cloud
cd ..

echo "build fe..."
cd fe
npm run build
cd ..
rm -rf release/docker/console
mkdir release/docker/console
cp -r fe/build/*  release/docker/console
cd release/docker
tar cvf console.tar ./console
rm -rf ./console
