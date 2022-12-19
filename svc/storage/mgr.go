package storage

import (
	"nas2cloud/svc/storage/external"
	"nas2cloud/svc/storage/store"
)

func List(username string, fullPath string) []*store.ObjectInfo {
	if fullPath == "" || fullPath == "/" {
		return getUserAuthorizedExternal(username)
	}
	return []*store.ObjectInfo{}
}

func getUserAuthorizedExternal(username string) []*store.ObjectInfo {
	list := external.AuthorizedVolumes("family")
	ret := make([]*store.ObjectInfo, 0)
	for _, p := range list {
		info := external.Store.Info(p)
		if info != nil {
			ret = append(ret, info)
		}
	}
	return ret
}
