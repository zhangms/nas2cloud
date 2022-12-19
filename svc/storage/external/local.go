package external

import (
	"nas2cloud/svc/storage/local"
	"nas2cloud/svc/storage/store"
	"path"
)

type extStoreLocal struct {
	volume *volume
}

func (e *extStoreLocal) List(fullPath string) []*store.ObjectInfo {
	ret := local.Store.List(path.Join(e.volume.endpoint, fullPath))
	for _, o := range ret {
		o.Path = path.Join(e.volume.protocol(), o.Path[len(e.volume.endpoint):])
	}
	return ret
}

func (e *extStoreLocal) Info(fullPath string) *store.ObjectInfo {
	o := local.Store.Info(path.Join(e.volume.endpoint, fullPath))
	if o != nil {
		o.Path = path.Join(e.volume.protocol(), o.Path[len(path.Join(e.volume.endpoint)):])
	}
	return o
}
