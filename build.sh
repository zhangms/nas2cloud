#!/bin/sh


cd server
CGO_ENABLED=0
GOOS=linux
GOARCH=amd64
go build

