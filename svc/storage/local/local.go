package local

import (
	"io/fs"
	"io/ioutil"
	"nas2cloud/libs"
	"nas2cloud/svc/storage/store"
	"os"
	"path"
	"strings"
)

type Store struct {
}

var Storage = &Store{}

func (s *Store) List(fullPath string) ([]*store.ObjectInfo, error) {
	info, err := s.Info(fullPath)
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
		inf, er := s.infoF(path.Join(fullPath, fi.Name()), fi)
		if er != nil {
			continue
		}
		ret = append(ret, inf)
	}
	return ret, nil
}

func (s *Store) Info(fullPath string) (*store.ObjectInfo, error) {
	fi, err := os.Stat(fullPath)
	if err != nil {
		return nil, err
	}
	return s.infoF(fullPath, fi)
}

func (s *Store) Read(fullPath string) ([]byte, error) {
	return ioutil.ReadFile(fullPath)
}

func (s *Store) Write(fullPath string, data []byte) error {
	return ioutil.WriteFile(fullPath, data, fs.ModePerm)
}

func (s *Store) infoF(fullPath string, fi os.FileInfo) (*store.ObjectInfo, error) {
	modTime := fi.ModTime()
	return &store.ObjectInfo{
		Name:    fi.Name(),
		Path:    fullPath,
		Type:    libs.If(fi.IsDir(), store.ObjectTypeDir, store.ObjectTypeFile).(store.ObjectType),
		Hidden:  strings.Index(fi.Name(), ".") == 0,
		ModTime: &modTime,
		Size:    fi.Size(),
	}, nil
}
