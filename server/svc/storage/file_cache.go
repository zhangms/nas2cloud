package storage

import (
	"encoding/json"
	"errors"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/libs/vfs/vpath"
	"nas2cloud/svc/cache"
	"strconv"
	"strings"
	"time"
)

type fileCacheMgr struct {
	version     string
	orderFields []string
}

var fileCache = &fileCacheMgr{
	version:     "v1",
	orderFields: []string{"fileName", "modTime", "creTime", "size"},
}

func (fc *fileCacheMgr) exists(path string) (bool, error) {
	key := fc.keyItem(path)
	count, err := cache.Exists(key)
	if err != nil {
		return false, err
	}
	return count == 1, nil
}

func (fc *fileCacheMgr) get(path string) (*vfs.ObjectInfo, error) {
	key := fc.keyItem(path)
	str, err := cache.Get(key)
	if err != nil {
		return nil, err
	}
	if len(str) == 0 {
		return nil, nil
	}
	obj := &vfs.ObjectInfo{}
	err = json.Unmarshal([]byte(str), obj)
	if err != nil {
		return nil, err
	}
	return obj, nil
}

func (fc *fileCacheMgr) saveIfAbsent(item *vfs.ObjectInfo) error {
	exists, _ := fc.exists(item.Path)
	if exists {
		return nil
	}
	return fc.save(item)
}

func (fc *fileCacheMgr) save(item *vfs.ObjectInfo) error {
	data, err := json.Marshal(item)
	if err != nil {
		return err
	}
	key := fc.keyItem(item.Path)
	_, err = cache.Set(key, string(data))
	if err != nil {
		return err
	}
	//更新在父目录中的位置
	parent := vpath.Dir(item.Path)
	for _, orderField := range fc.orderFields {
		rank := fc.keyRankInParent(parent, orderField)
		_, err = cache.ZAdd(rank, fc.getRankScore(item, orderField), item.Name)
		if err != nil {
			return err
		}
	}
	logger.Info("save file cache", item.Path)
	return nil
}

func (fc *fileCacheMgr) keyItem(path string) string {
	cp := vpath.Clean(path)
	bucket, _ := vpath.BucketFile(cp)
	return cache.Join(bucket, fc.version, "file", cp)
}

func (fc *fileCacheMgr) keyRankInParent(parent string, orderField string) string {
	cp := vpath.Clean(parent)
	bucket, _ := vpath.BucketFile(cp)
	return cache.Join(bucket, fc.version, "rank", orderField, cp)
}

func (fc *fileCacheMgr) keyWalkFlag(path string) string {
	cp := vpath.Clean(path)
	bucket, _ := vpath.BucketFile(cp)
	return cache.Join(bucket, fileCache.version, "walk_flag", cp)
}

func (fc *fileCacheMgr) walkFlag(path string) (bool, error) {
	flag := fc.keyWalkFlag(path)
	ok, err := cache.SetNXExpire(flag, time.Now().String(), cache.DefaultExpireTime)
	return ok, err
}

func (fc *fileCacheMgr) getRankScore(item *vfs.ObjectInfo, field string) float64 {
	switch field {
	case "fileName":
		if item.Type == vfs.ObjectTypeDir {
			return float64(128)
		} else {
			return float64(256)
		}
	case "size":
		return float64(item.Size)
	case "modTime":
		str := item.ModTime.Format("20060102150405")
		val, _ := strconv.Atoi(str)
		return float64(val)
	case "creTime":
		str := item.CreTime.Format("20060102150405")
		val, _ := strconv.Atoi(str)
		return float64(val)
	default:
		return 0
	}
}

func (fc *fileCacheMgr) zRange(path string, orderBy string, start int64, stop int64) ([]any, int64, error) {
	arr := strings.Split(orderBy, "_")
	fieldName := arr[0]
	sort := libs.IF(len(arr) > 1, func() any {
		return arr[1]
	}, func() any {
		return "asc"
	}).(string)
	key := fc.keyRankInParent(path, fieldName)
	total, err := cache.ZCard(key)
	if err != nil {
		return nil, 0, err
	}
	if total == 0 {
		return []any{}, 0, nil
	}
	var list []string
	if sort == "desc" {
		list, err = cache.ZRevRange(key, start, stop)
	} else {
		list, err = cache.ZRange(key, start, stop)
	}
	if err != nil {
		return nil, 0, err
	}
	keys := make([]string, 0, len(list))
	for _, name := range list {
		keys = append(keys, fc.keyItem(vpath.Join(path, name)))
	}
	ret, err := cache.MGet(keys...)
	return ret, total, err
}

func (fc *fileCacheMgr) delete(path string) error {
	//删除子文件
	children, err := cache.ZRange(fc.keyRankInParent(path, "fileName"), 0, -1)
	if err != nil {
		return err
	}
	for _, child := range children {
		_, err = cache.Del(fc.keyItem(vpath.Join(path, child)))
		if err != nil {
			return err
		}
	}
	//删除自己
	_, err = cache.Del(fc.keyItem(path))
	if err != nil {
		return err
	}
	for _, field := range fc.orderFields {
		_, err = cache.Del(fc.keyRankInParent(path, field))
		if err != nil {
			return err
		}
	}
	//删除父目录中的引用
	dir, name := vpath.Split(path)
	for _, orderField := range fc.orderFields {
		rank := fc.keyRankInParent(dir, orderField)
		_, err := cache.ZRem(rank, name)
		if err != nil {
			return err
		}
	}
	return nil
}

func (fc *fileCacheMgr) updateSize(userRoles, file string, size int64) error {
	info, err := fc.get(file)
	if info == nil && err == nil {
		info, err = vfs.Info(userRoles, file)
	}
	if err != nil {
		return err
	}
	if info == nil {
		return errors.New("file not exists:" + file)
	}
	if info.Size == size {
		return nil
	}
	info.Size = size
	return fc.save(info)
}
