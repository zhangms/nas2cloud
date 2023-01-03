package vfs

import (
	"errors"
	"io"
	"time"
)

type empty struct {
}

func (e *empty) Name() string {
	return "empty"
}

func (e *empty) List(file string) ([]*ObjectInfo, error) {
	return nil, errors.New("cannot list")
}

func (e *empty) Info(file string) (*ObjectInfo, error) {
	return nil, errors.New("cannot get info")
}

func (e *empty) Read(file string) ([]byte, error) {
	return nil, errors.New("cannot read")
}

func (e *empty) Write(file string, data []byte) error {
	return errors.New("cannot write")
}

func (e *empty) Exists(file string) bool {
	return false
}

func (e *empty) MkdirAll(file string) error {
	return errors.New("not support operation")
}

func (e *empty) RemoveAll(file string) error {
	return errors.New("not support operation")
}

func (e *empty) Upload(file string, reader io.Reader, modTime time.Time) (int64, error) {
	return 0, errors.New("not support operation")
}
