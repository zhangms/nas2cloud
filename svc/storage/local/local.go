package local

import (
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	store2 "nas2cloud/svc/storage/store"
	"os"
	"path"
	"strings"
)

type store struct {
}

var Store = &store{}

func (l *store) List(fullPath string) []*store2.ObjectInfo {
	info := l.Info(fullPath)
	if info == nil || info.Type != store2.ObjectTypeDir {
		return []*store2.ObjectInfo{}
	}
	entries, err := os.ReadDir(fullPath)
	if err != nil {
		logger.ErrorStacktrace(err, fullPath)
		return []*store2.ObjectInfo{}
	}
	ret := make([]*store2.ObjectInfo, 0)
	for _, entry := range entries {
		fi, er := entry.Info()
		if er != nil || fi.Name() == "$RECYCLE.BIN" {
			continue
		}
		ret = append(ret, l.infoF(path.Join(fullPath, fi.Name()), fi))
	}
	return ret
}

func (l *store) Info(fullPath string) *store2.ObjectInfo {
	fi, err := os.Stat(fullPath)
	if err != nil {
		logger.ErrorStacktrace(err, fullPath)
		return nil
	}
	return l.infoF(fullPath, fi)
}

func (l *store) infoF(fullPath string, fi os.FileInfo) *store2.ObjectInfo {
	modTime := fi.ModTime()
	return &store2.ObjectInfo{
		Name:    fi.Name(),
		Path:    fullPath,
		Type:    libs.IF(fi.IsDir(), store2.ObjectTypeDir, store2.ObjectTypeFile).(store2.ObjectType),
		Hidden:  strings.Index(fi.Name(), ".") == 0,
		ModTime: &modTime,
		Size:    fi.Size(),
	}
}
