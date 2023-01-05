package storage

import (
	"encoding/json"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc/cache"
	"path/filepath"
	"strconv"
	"strings"
)

type fileCacheMgr struct {
	version     string
	orderFields []string
}

var fileCache = &fileCacheMgr{
	version:     "v1",
	orderFields: []string{"fileName", "modTime", "creTime", "size"},
}

func (r *fileCacheMgr) exists(path string) bool {
	key := r.keyItem(path)
	count, err := cache.Exists(key)
	return err == nil && count == 1
}

func (r *fileCacheMgr) save(item *vfs.ObjectInfo) error {
	key := r.keyItem(item.Path)
	count, err := cache.Exists(key)
	if err != nil {
		return err
	}
	if count > 0 {
		return nil
	}
	data, err := json.Marshal(item)
	if err != nil {
		return err
	}
	_, err = cache.Set(key, string(data))
	if err != nil {
		return err
	}
	//更新在父目录中的位置
	parent := filepath.Dir(item.Path)
	for _, orderField := range r.orderFields {
		rank := r.keyRankInParent(parent, orderField)
		_, err = cache.ZAdd(rank, r.getRankScore(item, orderField), item.Name)
		if err != nil {
			return err
		}
	}
	logger.Info("SAVE_FILE_CACHE", item.Path)
	return nil
}

func (r *fileCacheMgr) keyItem(path string) string {
	bucket, _ := vfs.GetBucketFile(path)
	return cache.Join(bucket, r.version, "file", path)
}

func (r *fileCacheMgr) keyRankInParent(parent string, orderField string) string {
	bucket, _ := vfs.GetBucketFile(parent)
	return cache.Join(bucket, r.version, "rank", orderField, parent)
}

func (r *fileCacheMgr) getRankScore(item *vfs.ObjectInfo, field string) float64 {
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

func (r *fileCacheMgr) zRange(path string, orderBy string, start int64, stop int64) ([]any, int64, error) {
	arr := strings.Split(orderBy, "_")
	fieldName := arr[0]
	sort := libs.IF(len(arr) > 1, func() any {
		return arr[1]
	}, func() any {
		return "asc"
	}).(string)
	key := r.keyRankInParent(path, fieldName)
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
		keys = append(keys, r.keyItem(filepath.Join(path, name)))
	}
	ret, err := cache.MGet(keys...)
	return ret, total, err
}

func (r *fileCacheMgr) delete(path string) error {
	//删除子文件
	children, err := cache.ZRange(r.keyRankInParent(path, "fileName"), 0, -1)
	if err != nil {
		return err
	}
	for _, child := range children {
		_, err = cache.Del(r.keyItem(filepath.Join(path, child)))
		if err != nil {
			return err
		}
	}
	//删除自己
	_, err = cache.Del(r.keyItem(path))
	if err != nil {
		return err
	}
	for _, field := range r.orderFields {
		_, err = cache.Del(r.keyRankInParent(path, field))
		if err != nil {
			return err
		}
	}
	//删除父目录中的引用
	dir, name := filepath.Split(path)
	for _, orderField := range r.orderFields {
		rank := r.keyRankInParent(dir, orderField)
		_, err = cache.ZRem(rank, name)
		if err != nil {
			return err
		}
	}
	return nil
}
