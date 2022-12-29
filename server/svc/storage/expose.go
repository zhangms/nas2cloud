package storage

import (
	"nas2cloud/libs/vfs"
	"nas2cloud/svc/cache"
	"nas2cloud/svc/storage/thumbs"
	"nas2cloud/svc/user"
)

func List(username string, fullPath string) ([]*vfs.ObjectInfo, error) {
	userGroupName := user.GetUserGroup(username)
	key := userGroupName + "_" + fullPath

	cache.Del(key)

	//result, ok, err := cache.ComputeIfAbsent(key, func(str string) (any, error) {
	//	ret := make([]*vfs.ObjectInfo, 0)
	//	err := json.Unmarshal([]byte(str), &ret)
	//	return ret, err
	//}, func() (any, error) {
	//	return vfs.List(userGroupName, fullPath)
	//})
	//if err != nil {
	//	return nil, err
	//}
	//info := result.([]*vfs.ObjectInfo)
	//if !ok {
	//	thumbs.BatchThumbnail(info)
	//}
	//return info, nil
	return nil, nil
}

func Info(username string, fullPath string) (*vfs.ObjectInfo, error) {
	userGroupName := user.GetUserGroup(username)
	info, err := vfs.Info(userGroupName, fullPath)
	if err != nil {
		return nil, err
	}
	thumbs.Thumbnail(info)
	return info, nil
}
