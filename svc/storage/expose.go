package storage

import (
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc/storage/thumbs"
	"nas2cloud/svc/user"
)

func List(username string, fullPath string) []*vfs.ObjectInfo {
	userGroupName := user.GetUserGroup(username)
	info, err := vfs.List(userGroupName, fullPath)
	if err != nil {
		logger.ErrorStacktrace(err)
		return []*vfs.ObjectInfo{}
	}
	thumbs.BatchThumbnail(info)
	return info
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
