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

const Protocol = "external:/"

type Volume struct {
	name      string
	mountType string
	endpoint  string
	authorize string
}

func (e *Volume) Authorized(groupName string) bool {
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

func (e *Volume) Protocol() string {
	return path.Join(Protocol, e.name)
}

var volumes map[string]*Volume
var volumeNames []string

func AuthorizedVolumes(groupName string) []string {
	ret := make([]string, 0)
	for _, name := range volumeNames {
		v := volumes[name]
		if v.Authorized(groupName) {
			ret = append(ret, v.Protocol())
		}
	}
	return ret
}

func GetVolume(fullPath string) (*Volume, string, error) {
	if strings.Index(fullPath, Protocol) != 0 {
		return nil, "", errors.New("not valid Store endpoint")
	}
	p := fullPath[len(Protocol):]
	arr := strings.SplitN(p, "/", 2)
	if volumes[arr[0]] == nil {
		return nil, "", errors.New("external volume not exists")
	}
	return volumes[arr[0]], libs.IF(len(arr) > 1, func() any {
		return arr[1]
	}, func() any {
		return ""
	}).(string), nil
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
	volumes = make(map[string]*Volume)
	volumeNames = make([]string, 0)
	for _, conf := range configs {
		volumeNames = append(volumeNames, conf.Name)
		volumes[conf.Name] = &Volume{
			name:      conf.Name,
			mountType: conf.MountType,
			endpoint:  path.Clean(conf.Endpoint),
			authorize: conf.Authorize,
		}
	}
}

var Storage = &Store{}

type Store struct {
}

func (s *Store) List(fullPath string) ([]*store.ObjectInfo, error) {
	ext, file, _ := GetVolume(fullPath)
	impl := s.getStoreImpl(ext)
	return impl.List(file)
}

func (s *Store) Info(fullPath string) (*store.ObjectInfo, error) {
	ext, file, _ := GetVolume(fullPath)
	impl := s.getStoreImpl(ext)
	return impl.Info(file)
}

func (s *Store) getStoreImpl(v *Volume) store.Store {
	if v == nil {
		return &storeEmpty{}
	}
	if v.mountType == "local" {
		return &storeLocal{volume: v}
	}
	return &storeEmpty{}
}
