package storage

import (
	"nas2cloud/libs/logger"
	"nas2cloud/svc/storage/external"
	"nas2cloud/svc/storage/local"
	"nas2cloud/svc/storage/store"
	"strings"
)

func authorized(groupName string, st store.Store, fullPath string) bool {
	switch st.(type) {
	case *external.Store:
		v, _, _ := external.GetVolume(fullPath)
		return v != nil && v.Authorized(groupName)
	case *local.Store:
		return true
	}
	return false
}

func getStore(fullPath string) store.Store {
	if strings.Index(fullPath, external.Protocol) == 0 {
		return external.Storage
	} else {
		return local.Storage
	}
}

func getAuthorizedExternal(userGroupName string) []*store.ObjectInfo {
	list := external.AuthorizedVolumes(userGroupName)
	ret := make([]*store.ObjectInfo, 0)
	for _, p := range list {
		info, err := external.Storage.Info(p)
		if err != nil {
			logger.ErrorStacktrace(err, p)
			continue
		}
		if info != nil {
			ret = append(ret, info)
		}
	}
	return ret
}
