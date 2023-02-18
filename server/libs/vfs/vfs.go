package vfs

import (
	"encoding/json"
	"errors"
	"io"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs/vpath"
	"nas2cloud/res"
	"strings"
	"time"
)

type Bucket struct {
	id        string
	name      string
	mountType string
	endpoint  string
	authorize string
	mode      string
	hidden    bool
}

func (b *Bucket) authorized(role string) bool {
	if b.authorize == "ALL" || b.authorize == "PUBLIC" {
		return true
	}
	auths := strings.Split(b.authorize, ",")
	roles := strings.Split(role, ",")
	for _, r := range roles {
		ro := strings.TrimSpace(r)
		if ro == "root" {
			return true
		}
		for _, auth := range auths {
			if strings.TrimSpace(auth) == ro {
				return true
			}
		}
	}
	return false
}

func (b *Bucket) MountType() string {
	return b.mountType
}

func (b *Bucket) MountTypeLocal() bool {
	return b.mountType == "local"
}

func (b *Bucket) Dir() string {
	return vpath.Clean(b.id)
}

func (b *Bucket) Endpoint() string {
	return b.endpoint
}

func (b *Bucket) Authorize() string {
	return b.authorize
}

var buckets map[string]*Bucket
var bucketIds []string

func Load(env string) {
	type config struct {
		Id        string `json:"id"`
		Name      string `json:"name"`
		MountType string `json:"mountType"`
		Endpoint  string `json:"endpoint"`
		Authorize string `json:"authorize"`
		Mode      string `json:"mode"`
		Hidden    bool   `json:"hidden"`
	}
	configs := make([]*config, 0)
	data, _ := res.ReadByEnv(env, "bucket.json")
	_ = json.Unmarshal(data, &configs)
	buckets = make(map[string]*Bucket)
	bucketIds = make([]string, 0)
	for _, conf := range configs {
		bucketIds = append(bucketIds, conf.Id)
		buckets[conf.Id] = &Bucket{
			id:        conf.Id,
			name:      conf.Name,
			mountType: conf.MountType,
			endpoint:  conf.Endpoint,
			authorize: conf.Authorize,
			mode:      conf.Mode,
			hidden:    conf.Hidden,
		}
	}
	logger.Info("vfs loaded", len(buckets))
}

func GetBucket(role string, file string) (*Bucket, string, error) {
	bucketId, fileName := vpath.BucketFile(file)
	b := buckets[bucketId]
	if b == nil {
		return nil, "", errors.New("Bucket not exists :" + bucketId)
	}
	if !b.authorized(role) {
		return nil, "", errors.New("no authority")
	}
	return b, fileName, nil
}

func GetStore(role string, file string) (Store, string, error) {
	b, f, err := GetBucket(role, file)
	if err != nil {
		return nil, f, err
	}
	if b.MountTypeLocal() {
		return &Local{bucket: b}, f, nil
	}
	return &empty{}, f, nil
}

func GetAllBucket() []*Bucket {
	ret := make([]*Bucket, 0)
	for _, name := range bucketIds {
		b := buckets[name]
		ret = append(ret, b)
	}
	return ret
}

func List(role string, file string) ([]*ObjectInfo, error) {
	if vpath.IsRootDir(file) {
		ret := make([]*ObjectInfo, 0)
		for _, b := range GetAllBucket() {
			if !b.authorized(role) {
				continue
			}
			if b.hidden {
				continue
			}
			inf, err := Info(role, b.Dir())
			if err != nil {
				continue
			}
			ret = append(ret, inf)
		}
		return ret, nil
	}
	store, f, err := GetStore(role, file)
	if err != nil {
		return nil, err
	}
	return store.List(f)
}

func Info(role string, file string) (*ObjectInfo, error) {
	if vpath.IsRootDir(file) {
		return &ObjectInfo{
			Name:   vpath.Separator,
			Path:   vpath.Separator,
			Hidden: false,
			Type:   ObjectTypeDir,
		}, nil
	}
	store, f, err := GetStore(role, file)
	if err != nil {
		return nil, err
	}
	return store.Info(f)
}

func Open(role string, file string) (io.Reader, error) {
	store, f, err := GetStore(role, file)
	if err != nil {
		return nil, err
	}
	if !store.IsWriteable() {
		return nil, errors.New("permission denied")
	}
	return store.Open(f)
}

func Read(role string, file string) ([]byte, error) {
	store, f, err := GetStore(role, file)
	if err != nil {
		return nil, err
	}
	return store.Read(f)
}

func Write(role string, file string, data []byte) error {
	store, f, err := GetStore(role, file)
	if err != nil {
		return err
	}
	if !store.IsWriteable() {
		return errors.New("permission denied")
	}
	return store.Write(f, data)
}

func Exists(role string, file string) bool {
	store, f, err := GetStore(role, file)
	if err != nil {
		return false
	}
	return store.Exists(f)
}

func MkdirAll(role string, path string) error {
	store, f, err := GetStore(role, path)
	if err != nil {
		return err
	}
	if !store.IsWriteable() {
		return errors.New("permission denied")
	}
	return store.MkdirAll(f)
}

func RemoveAll(role string, path string) error {
	store, f, err := GetStore(role, path)
	if err != nil {
		return err
	}
	if !store.IsWriteable() {
		return errors.New("permission denied")
	}
	return store.RemoveAll(f)
}

func Remove(role string, path string) error {
	store, f, err := GetStore(role, path)
	if err != nil {
		return err
	}
	if !store.IsWriteable() {
		return errors.New("permission denied")
	}
	return store.Remove(f)
}

func Upload(role string, path string, reader io.Reader, modTime time.Time) (int64, error) {
	store, f, err := GetStore(role, path)
	if err != nil {
		return 0, err
	}
	if !store.IsWriteable() {
		return 0, errors.New("permission denied")
	}
	return store.Upload(f, reader, modTime)
}
