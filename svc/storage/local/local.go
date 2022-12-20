package local

import (
	"nas2cloud/libs"
	"nas2cloud/svc/storage/store"
	"os"
	"path"
	"strings"
)

type Store struct {
}

var Storage = &Store{}

func (l *Store) List(fullPath string) ([]*store.ObjectInfo, error) {
	info, err := l.Info(fullPath)
	if err != nil {
		return nil, err
	}
	if info.Type != store.ObjectTypeDir {
		return []*store.ObjectInfo{}, nil
	}
	entries, err := os.ReadDir(fullPath)
	if err != nil {
		return nil, err
	}
	ret := make([]*store.ObjectInfo, 0)
	for _, entry := range entries {
		fi, er := entry.Info()
		if er != nil {
			continue
		}
		if fi.Name() == "$RECYCLE.BIN" {
			continue
		}
		inf, er := l.infoF(path.Join(fullPath, fi.Name()), fi)
		if er != nil {
			continue
		}
		ret = append(ret, inf)
	}
	return ret, nil
}

func (l *Store) Info(fullPath string) (*store.ObjectInfo, error) {
	fi, err := os.Stat(fullPath)
	if err != nil {
		return nil, err
	}
	return l.infoF(fullPath, fi)
}

func (l *Store) infoF(fullPath string, fi os.FileInfo) (*store.ObjectInfo, error) {
	modTime := fi.ModTime()
	return &store.ObjectInfo{
		Name:    fi.Name(),
		Path:    fullPath,
		Type:    libs.IF(fi.IsDir(), store.ObjectTypeDir, store.ObjectTypeFile).(store.ObjectType),
		Hidden:  strings.Index(fi.Name(), ".") == 0,
		ModTime: &modTime,
		Size:    fi.Size(),
	}, nil
}
