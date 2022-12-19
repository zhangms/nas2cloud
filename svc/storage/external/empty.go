package external

import (
	"nas2cloud/svc/storage/store"
)

type extStoreEmpty struct {
}

func (e *extStoreEmpty) List(fullPath string) []*store.ObjectInfo {
	return []*store.ObjectInfo{}
}

func (e *extStoreEmpty) Info(fullPath string) *store.ObjectInfo {
	return nil
}
