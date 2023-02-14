package files

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"nas2cloud/libs/vfs"
	"nas2cloud/libs/vfs/vpath"
	"nas2cloud/svc/user"
	"time"
)

type Svc struct {
}

var service = &Svc{}

func Service() *Svc {
	return service
}

var RetryLaterAgain = errors.New("RetryLaterAgain")

func (fs *Svc) Walk(username string, fullPath string, orderBy string, start int64, stop int64) (files []*vfs.ObjectInfo, total int64, err error) {
	userRoles := user.GetUserRoles(username)
	path := vpath.Clean(fullPath)
	if vpath.IsRootDir(path) {
		return fs.walkRoot(username, userRoles)
	}
	_, _, err = vfs.GetStore(userRoles, path)
	if err != nil {
		return nil, 0, err
	}
	eventFired, err := fileWatcher.tryFireWalkEvent(&fileEvent{
		eventType: eventWalk,
		userName:  username,
		userRoles: userRoles,
		path:      path,
	})
	if err != nil {
		return nil, 0, err
	}
	if eventFired {
		return nil, 0, RetryLaterAgain
	}
	arr, total, err := fileCache.zRange(path, orderBy, start, stop)
	if err != nil {
		return nil, 0, err
	}
	ret := fs.unmarshal(arr)
	thumbSvc.BatchThumbnail(ret)
	return ret, total, nil
}

func (fs *Svc) walkRoot(username, userRoles string) ([]*vfs.ObjectInfo, int64, error) {
	favors, err := fs.getFavors(username)
	if err != nil {
		return nil, 0, err
	}
	list, er := vfs.List(userRoles, vpath.Separator)
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
	ret := make([]*vfs.ObjectInfo, 0)
	ret = append(ret, favors...)
	ret = append(ret, list...)
	return ret, int64(len(ret)), nil
}

func (fs *Svc) unmarshal(arr []any) []*vfs.ObjectInfo {
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

func (fs *Svc) MkdirAll(username, fullPath string) error {
	userRoles := user.GetUserRoles(username)
	path := vpath.Clean(fullPath)
	exi, err := fileCache.exists(path)
	if err != nil {
		return err
	}
	if exi {
		return errors.New("file exists already")
	}
	err = vfs.MkdirAll(userRoles, path)
	if err != nil {
		return err
	}
	info, err := vfs.Info(userRoles, path)
	if err != nil {
		return err
	}
	return fileCache.save(info)
}

func (fs *Svc) Remove(username string, fullPath []string) error {
	userRoles := user.GetUserRoles(username)
	for _, p := range fullPath {
		path := vpath.Clean(p)
		err := vfs.Remove(userRoles, path)
		if err != nil {
			return err
		}
		err = fileCache.delete(path)
		if err != nil {
			return err
		}
		fileWatcher.fireEvent(&fileEvent{
			eventType: eventDelete,
			userName:  username,
			userRoles: userRoles,
			path:      path,
		})
	}
	return nil
}

func (fs *Svc) Create(username string, fullPath string, data []byte) error {
	userRoles := user.GetUserRoles(username)
	err := vfs.Write(userRoles, fullPath, data)
	if err != nil {
		return err
	}
	info, err := vfs.Info(userRoles, fullPath)
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
		userName:  username,
		userRoles: userRoles,
		path:      fullPath,
	})
	return nil
}

func (fs *Svc) Upload(username string, fullPath string, reader io.Reader, modTime time.Time) (*vfs.ObjectInfo, error) {
	userRoles := user.GetUserRoles(username)
	_, err := vfs.Upload(userRoles, fullPath, reader, modTime)
	if err != nil {
		return nil, err
	}
	info, err := vfs.Info(userRoles, fullPath)
	if err != nil {
		return nil, err
	}
	info.CreTime = time.Now()
	thumbSvc.Thumbnail(info)
	err = fileCache.save(info)
	if err != nil {
		return nil, err
	}
	fileWatcher.fireEvent(&fileEvent{
		eventType: eventCreate,
		userName:  username,
		userRoles: userRoles,
		path:      fullPath,
	})
	return info, err
}

func (fs *Svc) Exists(username string, fullPath string) (bool, error) {
	userRoles := user.GetUserRoles(username)
	_, _, err := vfs.GetStore(userRoles, fullPath)
	if err != nil {
		return false, err
	}
	exists, err := fileCache.exists(fullPath)
	if err != nil {
		return false, err
	}
	if exists {
		return true, nil
	}
	if !vfs.Exists(userRoles, fullPath) {
		return false, nil
	}
	info, err := vfs.Info(userRoles, fullPath)
	if err != nil {
		return false, err
	}
	return true, fileCache.save(info)
}
