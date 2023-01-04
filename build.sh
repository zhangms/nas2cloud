#!/bin/sh

echo "build server..."
cd server
export CGO_ENABLED=0
export GOOS=linux
export GOARCH=amd64
go build -o ../build/nas2cloud
cd ..

echo "build fe..."
cd fe
npm run build
cd ..
rm -rf build/console
mkdir build/console
cp -r fe/build/*  build/console

echo "copy to server..."
#scp -r build/* pmz@mini:/Users/pmz/NAS/nas2cloud/
