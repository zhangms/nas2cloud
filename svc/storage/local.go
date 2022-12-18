package storage

import (
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"os"
	"path"
	"strings"
)

type localStore struct {
}

var storeLocal = &localStore{}

func (l *localStore) list(fullPath string) []*ObjectInfo {
	info := l.info(fullPath)
	if info == nil || info.Type != ObjectTypeDir {
		return []*ObjectInfo{}
	}
	entries, err := os.ReadDir(fullPath)
	if err != nil {
		logger.ErrorStacktrace(err, fullPath)
		return []*ObjectInfo{}
	}
	ret := make([]*ObjectInfo, 0)
	for _, entry := range entries {
		fi, er := entry.Info()
		if er != nil {
			continue
		}
		ret = append(ret, l.infoF(path.Join(fullPath, fi.Name()), fi))
	}
	return ret
}

func (l *localStore) info(fullPath string) *ObjectInfo {
	fi, err := os.Stat(fullPath)
	if err != nil {
		logger.ErrorStacktrace(err, fullPath)
		return nil
	}
	return l.infoF(fullPath, fi)
}

func (l *localStore) infoF(fullPath string, fi os.FileInfo) *ObjectInfo {
	modTime := fi.ModTime()
	return &ObjectInfo{
		Name:    fi.Name(),
		Path:    fullPath,
		Type:    libs.IF(fi.IsDir(), ObjectTypeDir, ObjectTypeFile).(ObjectType),
		Hidden:  strings.Index(fi.Name(), ".") == 0,
		ModTime: &modTime,
		Size:    fi.Size(),
	}
}
