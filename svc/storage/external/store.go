package external

import (
	"encoding/json"
	"errors"
	"nas2cloud/libs"
	"nas2cloud/res"
	"nas2cloud/svc/storage/store"
	"path"
	"strings"
)

const protocol = "external:/"

type volume struct {
	name      string
	mountType string
	endpoint  string
	authorize string
}

func (e *volume) authorized(groupName string) bool {
	if e.authorize == "ALL" {
		return true
	}
	arr := strings.Split(e.authorize, ",")
	for _, v := range arr {
		if strings.TrimSpace(v) == groupName {
			return true
		}
	}
	return false
}

func (e *volume) protocol() string {
	return path.Join(protocol, e.name)
}

var volumes map[string]*volume

func AuthorizedVolumes(groupName string) []string {
	ret := make([]string, 0)
	for _, v := range volumes {
		if v.authorized(groupName) {
			ret = append(ret, v.protocol())
		}
	}
	return ret
}

func init() {
	type config struct {
		Name      string `json:"name"`
		MountType string `json:"mountType"`
		Endpoint  string `json:"endpoint"`
		Authorize string `json:"authorize"`
	}

	configs := make([]*config, 0)
	data, _ := res.ReadData("external.json")
	_ = json.Unmarshal(data, &configs)
	volumes = make(map[string]*volume)
	for _, conf := range configs {
		volumes[conf.Name] = &volume{
			name:      conf.Name,
			mountType: conf.MountType,
			endpoint:  conf.Endpoint,
			authorize: conf.Authorize,
		}
	}
}

var Store = &extStore{}

type extStore struct {
}

func (s *extStore) List(fullPath string) []*store.ObjectInfo {
	ext, file, _ := s.getExt(fullPath)
	impl := s.getStoreImpl(ext)
	return impl.List(file)
}

func (s *extStore) Info(fullPath string) *store.ObjectInfo {
	ext, file, _ := s.getExt(fullPath)
	impl := s.getStoreImpl(ext)
	return impl.Info(file)
}

func (s *extStore) getExt(fullPath string) (*volume, string, error) {
	if strings.Index(fullPath, protocol) != 0 {
		return nil, "", errors.New("not valid extStore endpoint")
	}
	p := fullPath[len(protocol):]
	arr := strings.SplitN(p, "/", 2)
	return volumes[arr[0]], libs.If(len(arr) > 1, func() any {
		return arr[1]
	}, func() any {
		return ""
	}).(string), nil
}

func (s *extStore) getStoreImpl(v *volume) store.Store {
	if v == nil {
		return &extStoreEmpty{}
	}
	if v.mountType == "local" {
		return &extStoreLocal{volume: v}
	}
	return &extStoreEmpty{}
}
