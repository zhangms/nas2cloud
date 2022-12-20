package external

import (
	"nas2cloud/svc/storage/store"
)

type storeEmpty struct {
}

func (e *storeEmpty) List(fullPath string) ([]*store.ObjectInfo, error) {
	return []*store.ObjectInfo{}, nil
}

func (e *storeEmpty) Info(fullPath string) (*store.ObjectInfo, error) {
	return &store.ObjectInfo{}, nil
}
