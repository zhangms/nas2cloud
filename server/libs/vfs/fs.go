package vfs

import (
	"encoding/json"
	"errors"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/res"
	"path"
	"strings"
)

type Bucket struct {
	name      string
	mountType string
	endpoint  string
	authorize string
}

func (b *Bucket) authorized(user string) bool {
	if b.authorize == "ALL" || user == "root" {
		return true
	}
	arr := strings.Split(b.authorize, ",")
	for _, v := range arr {
		if strings.TrimSpace(v) == user {
			return true
		}
	}
	return false
}

func (b *Bucket) dir() string {
	return path.Join("/", b.name)
}

func (b *Bucket) Endpoint() string {
	return b.endpoint
}

var buckets map[string]*Bucket
var bucketNames []string

func init() {
	type config struct {
		Name      string `json:"name"`
		MountType string `json:"mountType"`
		Endpoint  string `json:"endpoint"`
		Authorize string `json:"authorize"`
	}
	configs := make([]*config, 0)
	data, _ := res.ReadData("bucket.json")
	_ = json.Unmarshal(data, &configs)
	buckets = make(map[string]*Bucket)
	bucketNames = make([]string, 0)
	for _, conf := range configs {
		bucketNames = append(bucketNames, conf.Name)
		buckets[conf.Name] = &Bucket{
			name:      conf.Name,
			mountType: conf.MountType,
			endpoint:  path.Clean(conf.Endpoint),
			authorize: conf.Authorize,
		}
	}
	logger.Info("VFS initialized:", len(buckets))
}

func GetBucket(user string, file string) (*Bucket, string, error) {
	pth := path.Clean(libs.If(path.IsAbs(file), file, "/"+file).(string))
	arr := strings.SplitN(pth, "/", 3)
	b := buckets[arr[1]]
	if b == nil {
		return nil, "", errors.New("Bucket not exists :" + arr[1])
	}
	if !b.authorized(user) {
		return nil, "", errors.New("no authority")
	}
	if len(arr) == 3 {
		return b, arr[2], nil
	}
	return b, "", nil
}

func GetStore(user string, file string) (Store, string, error) {
	b, f, err := GetBucket(user, file)
	if err != nil {
		return nil, f, err
	}
	if b.mountType == "local" {
		return &Local{bucket: b}, f, nil
	}
	return &empty{}, f, nil
}

func List(user string, file string) ([]*ObjectInfo, error) {
	if file == "" || file == "/" {
		ret := make([]*ObjectInfo, 0)
		for _, name := range bucketNames {
			b := buckets[name]
			if !b.authorized(user) {
				continue
			}
			inf, err := Info(user, b.dir())
			if err != nil {
				continue
			}
			ret = append(ret, inf)
		}
		return ret, nil
	}
	store, f, err := GetStore(user, file)
	if err != nil {
		return nil, err
	}
	return store.List(f)
}

func Info(user string, file string) (*ObjectInfo, error) {
	if file == "" || file == "/" {
		return &ObjectInfo{
			Name:   "/",
			Path:   "/",
			Hidden: false,
			Type:   ObjectTypeDir,
		}, nil
	}
	store, f, err := GetStore(user, file)
	if err != nil {
		return nil, err
	}
	return store.Info(f)
}

func Read(user string, file string) ([]byte, error) {
	store, f, err := GetStore(user, file)
	if err != nil {
		return nil, err
	}
	return store.Read(f)
}

func Write(user string, file string, data []byte) error {
	store, f, err := GetStore(user, file)
	if err != nil {
		return err
	}
	return store.Write(f, data)
}

func Exists(user string, file string) bool {
	store, f, err := GetStore(user, file)
	if err != nil {
		return false
	}
	return store.Exists(f)
}
