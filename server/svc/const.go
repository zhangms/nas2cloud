package svc

import (
	"errors"
	"io/fs"
	"os"
)

func AppName() string {
	return "nas2cloud"
}

func GetTempDir() string {
	dir := "." + AppName() + "/temp"
	_ = os.MkdirAll(dir, fs.ModePerm)
	return dir
}

func GetTokenDir() string {
	dir := "." + AppName() + "/token"
	_ = os.MkdirAll(dir, fs.ModePerm)
	return dir
}

var RetryLaterAgain = errors.New("RetryLaterAgain")
