package storage

import (
	"nas2cloud/libs/vfs"
	"nas2cloud/svc/user"
	"path/filepath"
)

type FileSvc struct {
}

var fileSvc = &FileSvc{}

func File() *FileSvc {
	return fileSvc
}

func (s *FileSvc) CreateDirAll(u *user.User, fullPath string) error {
	path := filepath.Clean(fullPath)
	store, _, err := vfs.GetStore(u.Group, path)
	if err != nil {
		return err
	}
	err = vfs.CreateDirAll(u.Group, path)
	if err != nil {
		return err
	}
	return FileWalk().forcePostWalkPathEvent(store.Name(), u.Group, filepath.Dir(path))
}
