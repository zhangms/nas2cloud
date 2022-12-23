package external

import (
	"errors"
	"nas2cloud/svc/storage/store"
)

type storeEmpty struct {
}

func (s *storeEmpty) List(fullPath string) ([]*store.ObjectInfo, error) {
	return []*store.ObjectInfo{}, nil
}

func (s *storeEmpty) Info(fullPath string) (*store.ObjectInfo, error) {
	return &store.ObjectInfo{}, nil
}

func (s *storeEmpty) Read(fullPath string) ([]byte, error) {
	return nil, errors.New("can not read " + fullPath)
}

func (s *storeEmpty) Write(fullPath string, data []byte) error {
	return errors.New("can not write " + fullPath)
}
