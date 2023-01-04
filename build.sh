#!/bin/sh

echo "build server..."
cd server
export CGO_ENABLED=0
export GOOS=linux
export GOARCH=amd64
go build -o ../target/nas2cloud
cd ..

echo "build fe..."
cd fe
npm run build
cd ..
rm -rf target/console
mkdir target/console
cp -r fe/build/*  target/console
cd target
tar cvf console.tar ./console
rm -rf ./console
