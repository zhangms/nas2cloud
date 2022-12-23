package external

import (
	"nas2cloud/svc/storage/local"
	"nas2cloud/svc/storage/store"
	"path"
)

type storeLocal struct {
	volume *Volume
}

func (s *storeLocal) abs(fullPath string) string {
	return path.Join(s.volume.endpoint, fullPath)
}

func (s *storeLocal) translate(obj *store.ObjectInfo) {
	obj.Path = path.Join(s.volume.Protocol(), obj.Path[len(path.Join(s.volume.endpoint)):])
	if obj.Path == s.volume.Protocol() {
		obj.Name = s.volume.name
	}
}

func (s *storeLocal) List(fullPath string) ([]*store.ObjectInfo, error) {
	ret, err := local.Storage.List(s.abs(fullPath))
	if err != nil {
		return nil, err
	}
	for _, o := range ret {
		s.translate(o)
	}
	return ret, err
}

func (s *storeLocal) Info(fullPath string) (*store.ObjectInfo, error) {
	o, err := local.Storage.Info(s.abs(fullPath))
	if err != nil {
		return nil, err
	}
	s.translate(o)
	return o, nil
}

func (s *storeLocal) Read(fullPath string) ([]byte, error) {
	return local.Storage.Read(s.abs(fullPath))
}

func (s *storeLocal) Write(fullPath string, data []byte) error {
	return local.Storage.Write(s.abs(fullPath), data)
}
