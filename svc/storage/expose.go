package storage

import (
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc/user"
)

func List(username string, fullPath string) []*vfs.ObjectInfo {
	userGroupName := user.GetUserGroup(username)
	info, err := vfs.List(userGroupName, fullPath)
	if err != nil {
		logger.ErrorStacktrace(err)
		return []*vfs.ObjectInfo{}
	}
	return info
}

func Info(username string, fullPath string) (*vfs.ObjectInfo, error) {
	userGroupName := user.GetUserGroup(username)
	return vfs.Info(userGroupName, fullPath)
}
