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

type fileRepository struct {
	version     string
	orderFields []string
}

var fileRepo = &fileRepository{
	version:     "v1",
	orderFields: []string{"fileName", "modTime", "creTime", "size"},
}

func (r *fileRepository) exists(path string) bool {
	bucketName, _ := vfs.GetBucketFile(path)
	key := r.keyItem(bucketName, path)
	count, err := cache.Exists(key)
	return err == nil && count == 1
}

func (r *fileRepository) save(item *vfs.ObjectInfo) error {
	bucketName, _ := vfs.GetBucketFile(item.Path)
	key := r.keyItem(bucketName, item.Path)
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
		rank := r.keyRankInParent(bucketName, parent, orderField)
		_, err = cache.ZAdd(rank, r.getRankScore(item, orderField), item.Name)
		if err != nil {
			return err
		}
	}
	logger.Info("SAVE_FILE_CACHE", item.Path)
	return nil
}

func (r *fileRepository) keyItem(bucketName string, path string) string {
	return cache.Join(bucketName, r.version, "file", path)
}

func (r *fileRepository) keyRankInParent(bucketName string, parent string, orderField string) string {
	return cache.Join(bucketName, r.version, "rank", orderField, parent)
}

func (r *fileRepository) getRankScore(item *vfs.ObjectInfo, field string) float64 {
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

func (r *fileRepository) Range(path string, orderBy string, start int64, stop int64) ([]any, int64, error) {
	arr := strings.Split(orderBy, "_")
	fieldName := arr[0]
	sort := libs.IF(len(arr) > 1, func() any {
		return arr[1]
	}, func() any {
		return "asc"
	}).(string)
	bucketName, _ := vfs.GetBucketFile(path)
	key := r.keyRankInParent(bucketName, path, fieldName)
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
		keys = append(keys, r.keyItem(bucketName, filepath.Join(path, name)))
	}
	ret, err := cache.MGet(keys...)
	return ret, total, err
}

func (r *fileRepository) delete(path string) error {
	bucketName, _ := vfs.GetBucketFile(path)
	_, err := cache.Del(r.keyItem(bucketName, path))
	if err != nil {
		return err
	}
	dir, name := filepath.Split(path)
	for _, orderField := range r.orderFields {
		rank := r.keyRankInParent(bucketName, dir, orderField)
		_, err = cache.ZRem(rank, name)
		if err != nil {
			return err
		}
	}
	return nil
}