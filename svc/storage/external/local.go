package external

import (
	"nas2cloud/svc/storage/local"
	"nas2cloud/svc/storage/store"
	"path"
)

type storeLocal struct {
	volume *Volume
}

func (e *storeLocal) List(fullPath string) ([]*store.ObjectInfo, error) {
	ret, err := local.Storage.List(path.Join(e.volume.endpoint, fullPath))
	if err != nil {
		return nil, err
	}
	for _, o := range ret {
		o.Path = path.Join(e.volume.Protocol(), o.Path[len(e.volume.endpoint):])
	}
	return ret, err
}

func (e *storeLocal) Info(fullPath string) (*store.ObjectInfo, error) {
	o, err := local.Storage.Info(path.Join(e.volume.endpoint, fullPath))
	if err != nil {
		return nil, err
	}
	if fullPath == "/" || fullPath == "" {
		o.Name = e.volume.name
	}
	o.Path = path.Join(e.volume.Protocol(), o.Path[len(path.Join(e.volume.endpoint)):])
	return o, nil
}
