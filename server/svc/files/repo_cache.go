package files

import (
	"encoding/json"
	"fmt"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/libs/vfs/vpath"
	"nas2cloud/svc/cache"
	"strings"
)

// Deprecated
type repositoryCache struct {
	version     string
	orderFields []string
}

func (r *repositoryCache) exists(path string) (bool, error) {
	key := r.keyItem(path)
	count, err := cache.Exists(key)
	return count == 1, err
}

func (r *repositoryCache) get(path string) (*vfs.ObjectInfo, error) {
	key := r.keyItem(path)
	str, err := cache.Get(key)
	if err != nil {
		return nil, err
	}
	if len(str) == 0 {
		return nil, nil
	}
	obj := &vfs.ObjectInfo{}
	if err = json.Unmarshal([]byte(str), obj); err != nil {
		return nil, err
	}
	return obj, nil
}

func (r *repositoryCache) saveIfAbsent(item *vfs.ObjectInfo) error {
	if exists, _ := r.exists(item.Path); exists {
		return nil
	}
	return r.save(item)
}

func (r *repositoryCache) save(item *vfs.ObjectInfo) error {
	data, err := json.Marshal(item)
	if err != nil {
		return err
	}
	key := r.keyItem(item.Path)
	if _, err = cache.Set(key, string(data)); err != nil {
		return err
	}
	//更新在父目录中的位置
	parent := vpath.Dir(item.Path)
	for _, orderField := range r.orderFields {
		rank := r.keyRank(parent, orderField)
		if _, err = cache.ZAdd(rank, r.getRankScore(item, orderField), item.Name); err != nil {
			return err
		}
	}
	logger.Info("save file cache", item.Path)
	return nil
}

func (r *repositoryCache) keyItem(path string) string {
	cp := vpath.Clean(path)
	bucket, _ := vpath.BucketFile(cp)
	return cache.Join(bucket, r.version, "file", cp)
}

func (r *repositoryCache) keyRank(path string, orderField string) string {
	cp := vpath.Clean(path)
	bucket, _ := vpath.BucketFile(cp)
	return cache.Join(bucket, r.version, "rank", orderField, cp)
}

func (r *repositoryCache) getRankScore(item *vfs.ObjectInfo, field string) float64 {
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
		if item.ModTime <= 0 {
			return float64(0)
		}
		return float64(item.ModTime)
	case "creTime":
		if item.CreTime <= 0 {
			return float64(0)
		}
		return float64(item.CreTime)
	default:
		return 0
	}
}

func (r *repositoryCache) walk(path string, orderBy string, start int64, stop int64) ([]*vfs.ObjectInfo, int64, error) {
	arr := strings.Split(orderBy, "_")
	fieldName := arr[0]
	sort := libs.IF(len(arr) > 1, func() any {
		return arr[1]
	}, func() any {
		return "asc"
	}).(string)
	key := r.keyRank(path, fieldName)
	total, err := cache.ZCard(key)
	if err != nil {
		return nil, 0, err
	}
	if total == 0 {
		return []*vfs.ObjectInfo{}, 0, nil
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
		keys = append(keys, r.keyItem(vpath.Join(path, name)))
	}
	ret, err := cache.MGet(keys...)
	return r.unmarshal(ret), total, err
}

func (r *repositoryCache) unmarshal(arr []any) []*vfs.ObjectInfo {
	ret := make([]*vfs.ObjectInfo, 0, len(arr))
	for _, item := range arr {
		if item == nil {
			continue
		}
		str := fmt.Sprintf("%v", item)
		obj := &vfs.ObjectInfo{}
		e := json.Unmarshal([]byte(str), obj)
		if e != nil {
			continue
		}
		ret = append(ret, obj)
	}
	return ret
}

func (r *repositoryCache) delete(path string) error {
	//删除子文件
	children, err := cache.ZRange(r.keyRank(path, "fileName"), 0, -1)
	if err != nil {
		return err
	}
	for _, child := range children {
		_, err = cache.Del(r.keyItem(vpath.Join(path, child)))
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
		_, err = cache.Del(r.keyRank(path, field))
		if err != nil {
			return err
		}
	}
	//删除父目录中的引用
	dir, name := vpath.Split(path)
	for _, orderField := range r.orderFields {
		rank := r.keyRank(dir, orderField)
		_, err := cache.ZRem(rank, name)
		if err != nil {
			return err
		}
	}
	return nil
}

func (r *repositoryCache) updateSize(file string, size int64) error {
	info, _ := r.get(file)
	if info != nil && info.Size != size {
		info.Size = size
		return r.save(info)
	}
	return nil
}

func (r *repositoryCache) updatePreview(file string, preview string) error {
	info, _ := r.get(file)
	if info != nil && info.Preview != preview {
		info.Preview = preview
		if err := r.save(info); err != nil {
			logger.Error("updatePreview error", err)
		}
	}
	return nil
}

func (r *repositoryCache) updateDirModTimeByChildren(path string) error {
	info, _ := r.get(path)
	if info != nil && info.Type == vfs.ObjectTypeDir {
		keyModTime := r.keyRank(path, "modTime")
		score, _, _ := cache.ZMaxScore(keyModTime)
		if score <= 0 {
			return nil
		}
		info.ModTime = int64(score)
		if err := r.save(info); err != nil {
			logger.Error("updateDirModTimeByChildren error", err)
		}
	}
	return nil
}

func (r *repositoryCache) searchPhotos(buckets []string, searchAfter string) ([]*vfs.ObjectInfo, string, error) {
	panic("implement me")
}
