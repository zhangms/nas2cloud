#!/bin/sh

echo "build server..."
cd server
go build -o ../release/local/nas2cloud
cd ..

echo "build fe..."
cd fe
npm run build
cd ..
rm -rf release/local/console
mkdir release/local/console
cp -r fe/build/*  release/local/console

rm -rf /Users/ZMS/NAS/local
cp -r release/local /Users/ZMS/NAS/
