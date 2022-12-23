package storage

import (
	"errors"
	"nas2cloud/libs/logger"
	"nas2cloud/svc/storage/store"
	"nas2cloud/svc/user"
)

func List(username string, fullPath string) []*store.ObjectInfo {
	userGroupName := user.GetUserGroup(username)
	if fullPath == "" || fullPath == "/" {
		return getAuthorizedExternal(userGroupName)
	}
	st := getStore(fullPath)
	if !authorized(userGroupName, st, fullPath) {
		return []*store.ObjectInfo{}
	}
	ret, err := st.List(fullPath)
	if err != nil {
		logger.ErrorStacktrace(err, fullPath)
		return []*store.ObjectInfo{}
	}
	batchThumbnail(ret)
	return ret
}

func Info(username string, fullPath string) (*store.ObjectInfo, error) {
	if fullPath == "" || fullPath == "/" {
		return &store.ObjectInfo{
			Name: ".",
			Path: "/",
			Type: store.ObjectTypeDir,
		}, nil
	}
	userGroupName := user.GetUserGroup(username)
	st := getStore(fullPath)
	if !authorized(userGroupName, st, fullPath) {
		return nil, errors.New("no authority")
	}
	info, err := st.Info(fullPath)
	if err != nil {
		return nil, err
	}
	thumbnail(info)
	return info, nil
}
