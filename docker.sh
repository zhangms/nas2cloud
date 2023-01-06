#!/bin/sh

echo "build server..."
cd server
export CGO_ENABLED=0
export GOOS=linux
export GOARCH=amd64
go build -o ../docker/nas2cloud
cd ..

echo "build fe..."
cd fe
npm run build
cd ..
rm -rf docker/console
mkdir docker/console
cp -r fe/build/*  docker/console
cd docker
tar cvf console.tar ./console
rm -rf ./console
