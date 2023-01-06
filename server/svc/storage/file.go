package storage

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc"
	"nas2cloud/svc/user"
	"path/filepath"
	"time"
)

const sysUser = "root"

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
		return fs.walkRoot(userGroup)
	}
	_, _, err = vfs.GetStore(userGroup, path)
	if err != nil {
		return nil, 0, err
	}
	eventFired, err := fileWatcher.tryFireWalkEvent(&fileEvent{
		eventType: eventWalk,
		userGroup: userGroup,
		path:      path,
	})
	if err != nil {
		return nil, 0, err
	}
	if eventFired {
		return nil, 0, svc.RetryLaterAgain
	}
	arr, total, err := fileCache.zRange(path, orderBy, start, stop)
	if err != nil {
		return nil, 0, err
	}
	ret := fs.unmarshal(arr)
	thumbSvc.BatchThumbnail(ret)
	return ret, total, nil
}

func (fs *FileSvc) walkRoot(userGroup string) ([]*vfs.ObjectInfo, int64, error) {
	list, er := vfs.List(userGroup, "/")
	if er != nil {
		return nil, 0, er
	}
	files := make([]*vfs.ObjectInfo, 0)
	for _, d := range list {
		_ = fileCache.saveIfAbsent(d)
		inf, _ := fileCache.get(d.Path)
		if inf != nil {
			files = append(files, inf)
		}
	}
	return files, int64(len(files)), nil
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
	exi, err := fileCache.exists(path)
	if err != nil {
		return err
	}
	if exi {
		return errors.New("file exists already")
	}
	err = vfs.MkdirAll(userGroup, path)
	if err != nil {
		return err
	}
	info, err := vfs.Info(userGroup, path)
	if err != nil {
		return err
	}
	return fileCache.save(info)
}

func (fs *FileSvc) RemoveAll(username string, fullPath []string) error {
	userGroup := user.GetUserGroup(username)
	for _, p := range fullPath {
		path := filepath.Clean(p)
		err := vfs.RemoveAll(userGroup, path)
		if err != nil {
			return err
		}
		err = fileCache.delete(path)
		if err != nil {
			return err
		}
		fileWatcher.fireEvent(&fileEvent{
			eventType: eventDelete,
			userGroup: userGroup,
			path:      path,
		})
	}
	return nil
}

func (fs *FileSvc) Create(username string, fullPath string, data []byte) error {
	userGroup := user.GetUserGroup(username)
	err := vfs.Write(userGroup, fullPath, data)
	if err != nil {
		return err
	}
	info, err := vfs.Info(userGroup, fullPath)
	if err != nil {
		return err
	}
	thumbSvc.Thumbnail(info)
	err = fileCache.save(info)
	if err != nil {
		return err
	}
	fileWatcher.fireEvent(&fileEvent{
		eventType: eventCreate,
		userGroup: userGroup,
		path:      fullPath,
	})
	return nil
}

func (fs *FileSvc) Upload(username string, fullPath string, reader io.Reader, modTime time.Time) error {
	userGroup := user.GetUserGroup(username)
	_, err := vfs.Upload(userGroup, fullPath, reader, modTime)
	if err != nil {
		return err
	}
	info, err := vfs.Info(userGroup, fullPath)
	if err != nil {
		return err
	}
	info.CreTime = time.Now()
	thumbSvc.Thumbnail(info)
	err = fileCache.save(info)
	if err != nil {
		return err
	}
	fileWatcher.fireEvent(&fileEvent{
		eventType: eventCreate,
		userGroup: userGroup,
		path:      fullPath,
	})
	return nil
}

func (fs *FileSvc) Exists(username string, fullPath string) (bool, error) {
	exists, err := fileCache.exists(fullPath)
	if err != nil {
		return false, err
	}
	if exists {
		return true, nil
	}
	userGroup := user.GetUserGroup(username)
	if !vfs.Exists(userGroup, fullPath) {
		return false, nil
	}
	info, err := vfs.Info(userGroup, fullPath)
	if err != nil {
		return false, err
	}
	return true, fileCache.save(info)
}
