package vfs

import "errors"

type empty struct {
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
