package vfs

import (
	"encoding/json"
	"errors"
	"io"
	"nas2cloud/env"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/res"
	"path"
	"path/filepath"
	"strings"
	"time"
)

type Bucket struct {
	name      string
	mountType string
	endpoint  string
	authorize string
	hidden    bool
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

func (b *Bucket) MountType() string {
	return b.mountType
}

func (b *Bucket) Dir() string {
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
		Hidden    bool   `json:"hidden"`
	}
	configs := make([]*config, 0)
	data, _ := res.ReadData(env.GetProfileActive() + "/bucket.json")
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
			hidden:    conf.Hidden,
		}
	}
	logger.Info("VFS initialized", len(buckets))
}

func GetBucketFile(file string) (string, string) {
	pth := path.Clean(libs.If(path.IsAbs(file), file, "/"+file).(string))
	arr := strings.SplitN(pth, "/", 3)
	if len(arr) == 3 {
		return arr[1], arr[2]
	}
	return arr[1], ""
}

func GetBucket(user string, file string) (*Bucket, string, error) {
	bucketName, fileName := GetBucketFile(file)
	b := buckets[bucketName]
	if b == nil {
		return nil, "", errors.New("Bucket not exists :" + bucketName)
	}
	if !b.authorized(user) {
		return nil, "", errors.New("no authority")
	}
	return b, fileName, nil
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

func IsRootDir(p string) bool {
	clean := filepath.Clean(p)
	return clean == "" || clean == "." || clean == "/"
}

func GetAllBucket() []*Bucket {
	ret := make([]*Bucket, 0)
	for _, name := range bucketNames {
		b := buckets[name]
		ret = append(ret, b)
	}
	return ret
}

func List(user string, file string) ([]*ObjectInfo, error) {
	if IsRootDir(file) {
		ret := make([]*ObjectInfo, 0)
		for _, b := range GetAllBucket() {
			if !b.authorized(user) {
				continue
			}
			if b.hidden {
				continue
			}
			inf, err := Info(user, b.Dir())
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
			Name:    "/",
			Path:    "/",
			Hidden:  false,
			Type:    ObjectTypeDir,
			ModTime: time.Now(),
			CreTime: time.Now(),
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

func MkdirAll(user string, path string) error {
	store, f, err := GetStore(user, path)
	if err != nil {
		return err
	}
	return store.MkdirAll(f)
}

func RemoveAll(user string, path string) error {
	store, f, err := GetStore(user, path)
	if err != nil {
		return err
	}
	return store.RemoveAll(f)
}

func Upload(user string, path string, reader io.Reader, modTime time.Time) (int64, error) {
	store, f, err := GetStore(user, path)
	if err != nil {
		return 0, err
	}
	return store.Upload(f, reader, modTime)
}
