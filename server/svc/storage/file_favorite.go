package storage

import (
	"nas2cloud/libs/vfs"
	"nas2cloud/svc/cache"
	"sort"
	"strings"
)

func (fs *FileSvc) ToggleFavorite(username, favorName, fullPath string) (bool, error) {
	key := fs.keyFavor(username)
	exists, err := cache.HExists(key, fullPath)
	if err != nil {
		return exists, err
	}
	if exists {
		_, err = cache.HDel(key, fullPath)
		return false, err
	} else {
		_, err = cache.HSet(key, fullPath, favorName)
		return true, err
	}
}

func (fs *FileSvc) keyFavor(username string) string {
	return cache.Join(username, "favorite_files")
}

func (fs *FileSvc) GetFavorsMap(username string) (map[string]string, error) {
	key := fs.keyFavor(username)
	return cache.HGetAll(key)
}

func (fs *FileSvc) getFavors(username string) ([]*vfs.ObjectInfo, error) {
	key := fs.keyFavor(username)
	mp, err := cache.HGetAll(key)
	if err != nil {
		return nil, err
	}
	list := make([]*vfs.ObjectInfo, 0)
	for path, name := range mp {
		info, _ := fileCache.get(path)
		if info != nil {
			info.Name = name
			list = append(list, info)
		}
	}
	sort.Slice(list, func(i, j int) bool {
		return strings.Compare(list[i].Name, list[j].Name) < 0
	})
	return list, nil
}
