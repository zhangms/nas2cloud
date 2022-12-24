package vfs

import (
	"encoding/json"
	"errors"
	"nas2cloud/libs"
	"nas2cloud/res"
	"path"
	"strings"
)

type bucket struct {
	name      string
	mountType string
	endpoint  string
	authorize string
}

func (b *bucket) authorized(user string) bool {
	if b.authorize == "ALL" {
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

func (b *bucket) dir() string {
	return path.Join("/", b.name)
}

var buckets map[string]*bucket
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
	buckets = make(map[string]*bucket)
	bucketNames = make([]string, 0)
	for _, conf := range configs {
		bucketNames = append(bucketNames, conf.Name)
		buckets[conf.Name] = &bucket{
			name:      conf.Name,
			mountType: conf.MountType,
			endpoint:  path.Clean(conf.Endpoint),
			authorize: conf.Authorize,
		}
	}
}

func getBucket(user string, file string) (*bucket, string, error) {
	pth := path.Clean(libs.If(path.IsAbs(file), file, "/"+file).(string))
	arr := strings.SplitN(pth, "/", 3)
	b := buckets[arr[1]]
	if b == nil {
		return nil, "", errors.New("bucket not exists :" + arr[1])
	}
	if !b.authorized(user) {
		return nil, "", errors.New("no authority")
	}
	if len(arr) == 3 {
		return b, arr[2], nil
	}
	return b, "", nil
}

func getStore(user string, file string) (Store, string, error) {
	b, f, err := getBucket(user, file)
	if err != nil {
		return nil, f, err
	}
	if b.mountType == "local" {
		return &vLocal{bucket: b}, f, nil
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
	store, f, err := getStore(user, file)
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
	store, f, err := getStore(user, file)
	if err != nil {
		return nil, err
	}
	return store.Info(f)
}

func Read(user string, file string) ([]byte, error) {
	store, f, err := getStore(user, file)
	if err != nil {
		return nil, err
	}
	return store.Read(f)
}

func Write(user string, file string, data []byte) error {
	store, f, err := getStore(user, file)
	if err != nil {
		return err
	}
	return store.Write(f, data)
}
