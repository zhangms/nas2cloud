package storage

import (
	"encoding/json"
	"errors"
	"fmt"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc"
	"nas2cloud/svc/user"
	"path/filepath"
)

type FileSvc struct {
}

var fileSvc = &FileSvc{}

func File() *FileSvc {
	return fileSvc
}

func (fs *FileSvc) Walk(username string, fullPath string, orderBy string, start int64, stop int64) (files []*vfs.ObjectInfo, total int64, err error) {
	userGroup := user.GetUserGroup(username)
	path := filepath.Clean(fullPath)
	if vfs.IsRootDir(path) {
		ls, er := vfs.List(userGroup, path)
		return ls, int64(len(ls)), er
	}
	store, _, err := vfs.GetStore(userGroup, path)
	if err != nil {
		return nil, 0, err
	}
	eventFired, err := fileWatcher.tryFireWalkEvent(&fileEvent{
		eventType: eventWalk,
		userGroup: userGroup,
		storeName: store.Name(),
		path:      path,
	})
	if err != nil {
		return nil, 0, err
	}
	if eventFired {
		return nil, 0, svc.RetryLaterAgain
	}
	arr, total, err := fileRepo.Range(path, orderBy, start, stop)
	if err != nil {
		return nil, 0, err
	}
	ret := fs.unmarshal(arr)
	return ret, total, nil
}

func (fs *FileSvc) unmarshal(arr []any) []*vfs.ObjectInfo {
	ret := make([]*vfs.ObjectInfo, 0, len(arr))
	for _, item := range arr {
		if item == nil {
			continue
		}
		str := fmt.Sprintf("%v", item)
		obj := &vfs.ObjectInfo{}
		e := json.Unmarshal([]byte(str), obj)
		if e != nil {
			continue
		}
		ret = append(ret, obj)
	}
	return ret
}

func (fs *FileSvc) MkdirAll(username, fullPath string) error {
	userGroup := user.GetUserGroup(username)
	path := filepath.Clean(fullPath)
	if fileRepo.exists(path) {
		return errors.New("file exists already")
	}
	err := vfs.MkdirAll(userGroup, path)
	if err != nil {
		return err
	}
	info, err := vfs.Info(userGroup, path)
	if err != nil {
		return err
	}
	return fileRepo.save(info)
}

func (fs *FileSvc) RemoveAll(username string, fullPath string) error {
	userGroup := user.GetUserGroup(username)
	path := filepath.Clean(fullPath)
	if !vfs.Exists(userGroup, path) {
		return errors.New("file not exists")
	}
	err := vfs.RemoveAll(userGroup, path)
	if err != nil {
		return err
	}
	return fileRepo.delete(path)
}
