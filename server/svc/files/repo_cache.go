package files

import (
	"encoding/json"
	"errors"
	"fmt"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/libs/vfs/vpath"
	"nas2cloud/svc/cache"
	"strconv"
	"strings"
	"time"
)

type repositoryCache struct {
	version     string
	orderFields []string
}

func (repo *repositoryCache) exists(path string) (bool, error) {
	key := repo.keyItem(path)
	count, err := cache.Exists(key)
	if err != nil {
		return false, err
	}
	return count == 1, nil
}

func (repo *repositoryCache) get(path string) (*vfs.ObjectInfo, error) {
	key := repo.keyItem(path)
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

func (repo *repositoryCache) saveIfAbsent(item *vfs.ObjectInfo) error {
	exists, _ := repo.exists(item.Path)
	if exists {
		return nil
	}
	return repo.save(item)
}

func (repo *repositoryCache) save(item *vfs.ObjectInfo) error {
	data, err := json.Marshal(item)
	if err != nil {
		return err
	}
	//获取目录的最新修改时间
	if item.Type == vfs.ObjectTypeDir {
		keyModTime := repo.keyRankInParent(item.Path, "modTime")
		score, _, _ := cache.ZMaxScore(keyModTime)
		if score > 0 {
			tm, er := time.Parse("20060102150405", fmt.Sprintf("%d", int64(score)))
			if er != nil {
				item.ModTime = tm
			}
		}
	}
	key := repo.keyItem(item.Path)
	_, err = cache.Set(key, string(data))
	if err != nil {
		return err
	}
	//更新在父目录中的位置
	parent := vpath.Dir(item.Path)
	for _, orderField := range repo.orderFields {
		rank := repo.keyRankInParent(parent, orderField)
		_, err = cache.ZAdd(rank, repo.getRankScore(item, orderField), item.Name)
		if err != nil {
			return err
		}
	}
	logger.Info("save file cache", item.Path)
	return nil
}

func (repo *repositoryCache) keyItem(path string) string {
	cp := vpath.Clean(path)
	bucket, _ := vpath.BucketFile(cp)
	return cache.Join(bucket, repo.version, "file", cp)
}

func (repo *repositoryCache) keyRankInParent(parent string, orderField string) string {
	cp := vpath.Clean(parent)
	bucket, _ := vpath.BucketFile(cp)
	return cache.Join(bucket, repo.version, "rank", orderField, cp)
}

func (repo *repositoryCache) getRankScore(item *vfs.ObjectInfo, field string) float64 {
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
		val, _ := strconv.ParseInt(str, 10, 64)
		return float64(val)
	case "creTime":
		str := item.CreTime.Format("20060102150405")
		val, _ := strconv.ParseInt(str, 10, 64)
		return float64(val)
	default:
		return 0
	}
}

func (repo *repositoryCache) find(path string, orderBy string, start int64, stop int64) ([]*vfs.ObjectInfo, int64, error) {
	arr := strings.Split(orderBy, "_")
	fieldName := arr[0]
	sort := libs.IF(len(arr) > 1, func() any {
		return arr[1]
	}, func() any {
		return "asc"
	}).(string)
	key := repo.keyRankInParent(path, fieldName)
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
		keys = append(keys, repo.keyItem(vpath.Join(path, name)))
	}
	ret, err := cache.MGet(keys...)
	return repo.unmarshal(ret), total, err
}

func (repo *repositoryCache) unmarshal(arr []any) []*vfs.ObjectInfo {
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

func (repo *repositoryCache) delete(path string) error {
	//删除子文件
	children, err := cache.ZRange(repo.keyRankInParent(path, "fileName"), 0, -1)
	if err != nil {
		return err
	}
	for _, child := range children {
		_, err = cache.Del(repo.keyItem(vpath.Join(path, child)))
		if err != nil {
			return err
		}
	}
	//删除自己
	_, err = cache.Del(repo.keyItem(path))
	if err != nil {
		return err
	}
	for _, field := range repo.orderFields {
		_, err = cache.Del(repo.keyRankInParent(path, field))
		if err != nil {
			return err
		}
	}
	//删除父目录中的引用
	dir, name := vpath.Split(path)
	for _, orderField := range repo.orderFields {
		rank := repo.keyRankInParent(dir, orderField)
		_, err := cache.ZRem(rank, name)
		if err != nil {
			return err
		}
	}
	return nil
}

func (repo *repositoryCache) updateSize(userRoles, file string, size int64) error {
	info, err := repo.get(file)
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
	return repo.save(info)
}

func (repo *repositoryCache) updatePreview(file string, preview string) {
	info, _ := repo.get(file)
	if info != nil {
		info.Preview = preview
		if err := repo.save(info); err != nil {
			logger.Error("updatePreview error", err)
		}
	}
}
