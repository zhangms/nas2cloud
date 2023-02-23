package files

import (
	"context"
	"errors"
	"io"
	"nas2cloud/libs/vfs"
	"nas2cloud/libs/vfs/vpath"
	"nas2cloud/svc/user"
	"sync"
	"time"
)

const sysUser = "root"

var initOnce = &sync.Once{}

var RetryLaterAgain = errors.New("RetryLaterAgain")

func DoInit(env string, ctx context.Context) {
	initOnce.Do(func() {
		vfs.Load(env)
		initRepository(env)
		startEventProcessor(ctx)
		startThumbnailExecutor(ctx)
		startDiskUsage(ctx)
	})
}

func Walk(username string, fullPath string, orderBy string, start int64, stop int64) (files []*vfs.ObjectInfo, total int64, err error) {
	userRoles := user.GetUserRoles(username)
	path := vpath.Clean(fullPath)
	if vpath.IsRootDir(path) {
		return walkRoot(username, userRoles)
	}
	_, _, err = vfs.GetStore(userRoles, path)
	if err != nil {
		return nil, 0, err
	}
	eventFired, err := evt.tryFireWalk(&event{
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
	arr, total, err := repo.find(path, orderBy, start, stop)
	if err != nil {
		return nil, 0, err
	}
	return arr, total, nil
}

func walkRoot(username, userRoles string) ([]*vfs.ObjectInfo, int64, error) {
	ret := make([]*vfs.ObjectInfo, 0)
	favors, err := getFavors(username)
	if err != nil {
		return nil, 0, err
	}
	ret = append(ret, favors...)

	list, er := vfs.List(userRoles, vpath.Separator)
	if er != nil {
		return nil, 0, er
	}
	files := make([]*vfs.ObjectInfo, 0)
	for _, d := range list {
		_ = repo.saveIfAbsent(d)
		inf, _ := repo.get(d.Path)
		if inf != nil {
			files = append(files, inf)
		}
	}
	ret = append(ret, files...)
	return ret, int64(len(ret)), nil
}

func MkdirAll(username, fullPath string) error {
	userRoles := user.GetUserRoles(username)
	path := vpath.Clean(fullPath)
	exi, err := repo.exists(path)
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
	return repo.save(info)
}

func Remove(username string, fullPath []string) error {
	userRoles := user.GetUserRoles(username)
	for _, p := range fullPath {
		path := vpath.Clean(p)
		err := vfs.Remove(userRoles, path)
		if err != nil {
			return err
		}
		err = repo.delete(path)
		if err != nil {
			return err
		}
		evt.fire(&event{
			eventType: eventDelete,
			userName:  username,
			userRoles: userRoles,
			path:      path,
		})
	}
	return nil
}

func Upload(username string, fullPath string, reader io.Reader, modTime time.Time) (*vfs.ObjectInfo, error) {
	userRoles := user.GetUserRoles(username)
	_, err := vfs.Upload(userRoles, fullPath, reader, modTime)
	if err != nil {
		return nil, err
	}
	info, err := vfs.Info(userRoles, fullPath)
	if err != nil {
		return nil, err
	}
	info.CreTime = time.Now().UnixMilli()
	thumbExecutor.post(info)
	err = repo.save(info)
	if err != nil {
		return nil, err
	}
	evt.fire(&event{
		eventType: eventCreate,
		userName:  username,
		userRoles: userRoles,
		path:      fullPath,
	})
	return info, err
}

func Exists(username string, fullPath string) (bool, error) {
	userRoles := user.GetUserRoles(username)
	_, _, err := vfs.GetStore(userRoles, fullPath)
	if err != nil {
		return false, err
	}
	exists, err := repo.exists(fullPath)
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
	return true, repo.save(info)
}
