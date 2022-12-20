package storage

import (
	"nas2cloud/libs/logger"
	"nas2cloud/svc/storage/store"
)

func List(username string, fullPath string) []*store.ObjectInfo {
	userGroupName := "family"
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
	return ret
}
