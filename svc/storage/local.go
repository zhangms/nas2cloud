package storage

import (
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"os"
	"strings"
)

type LocalStore struct {
}

func (l *LocalStore) List(path string) []*ObjectInfo {
	fi, err := os.Stat(path)
	if err != nil {
		logger.ErrorStacktrace(err, path)
		return []*ObjectInfo{}
	}
	parse := func(fi os.FileInfo) *ObjectInfo {
		modTime := fi.ModTime()
		return &ObjectInfo{
			Name:    fi.Name(),
			Path:    path,
			Type:    libs.IF(fi.IsDir(), ObjectTypeDir, ObjectTypeFile).(ObjectType),
			Hidden:  strings.Index(fi.Name(), ".") == 0,
			ModTime: &modTime,
			Size:    fi.Size(),
		}
	}
	if !fi.IsDir() {
		return []*ObjectInfo{parse(fi)}
	}
	entries, err := os.ReadDir(path)
	if err != nil {
		logger.ErrorStacktrace(err, path)
		return []*ObjectInfo{}
	}
	ret := make([]*ObjectInfo, 0)
	for _, entry := range entries {
		info, er := entry.Info()
		if er != nil {
			continue
		}
		ret = append(ret, parse(info))
	}
	return ret
}
