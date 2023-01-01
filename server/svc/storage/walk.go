package storage

import (
	"encoding/json"
	"fmt"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc"
	"nas2cloud/svc/cache"
	"nas2cloud/svc/user"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

type FileWalkSvc struct {
	version string
}

var fileWalkSvc = &FileWalkSvc{
	version: "v1",
}

func FileWalk() *FileWalkSvc {
	return fileWalkSvc
}

func (fs *FileWalkSvc) Walk(username string, fullPath string, orderBy string, start int64, stop int64) (files []*vfs.ObjectInfo, total int64, err error) {
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
	taskPosted, err := fs.tryPostWalkPathEvent(store.Name(), userGroup, path)
	if err != nil {
		return nil, 0, err
	}
	if taskPosted {
		return nil, 0, svc.RetryLaterAgain
	}
	arr, total, err := fs.getFromCache(store.Name(), path, orderBy, start, stop)
	if err != nil {
		return nil, 0, err
	}
	ret := fs.unmarshal(arr)
	return ret, total, nil
}

func (fs *FileWalkSvc) unmarshal(arr []any) []*vfs.ObjectInfo {
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

func (fs *FileWalkSvc) keyRank(storeName string, path string, orderField string) string {
	return cache.Join(storeName, fs.version, "rank", path, "order", orderField)
}

func (fs *FileWalkSvc) keyItem(storeName string, path string, name string) string {
	return cache.Join(storeName, fs.version, "file", filepath.Join(path, name))
}

func (fs *FileWalkSvc) keyWalkFlag(storeName string, path string) string {
	return cache.Join(storeName, fs.version, "flag", path)
}

func (fs *FileWalkSvc) getFromCache(storeName string, path string, orderBy string, start int64, stop int64) ([]any, int64, error) {
	sort := strings.SplitN(orderBy, "_", 2)
	key := fs.keyRank(storeName, path, sort[0])
	total, err := cache.ZCard(key)
	if err != nil {
		return nil, 0, err
	}
	var list []string
	if len(sort) > 1 && sort[1] == "desc" {
		list, err = cache.ZRevRange(key, start, stop)
	} else {
		list, err = cache.ZRange(key, start, stop)
	}
	if err != nil {
		return nil, 0, err
	}
	keys := make([]string, 0, len(list))
	for _, name := range list {
		keys = append(keys, fs.keyItem(storeName, path, name))
	}
	arr, err := cache.MGet(keys...)
	return arr, total, nil
}

func (fs *FileWalkSvc) tryPostWalkPathEvent(storeName string, userGroup string, path string) (bool, error) {
	flag := fs.keyWalkFlag(storeName, path)
	ok, err := cache.SetNXExpire(flag, time.Now().String(), cache.DefaultExpireTime)
	if ok {
		fileWalker.postWalkEvent(userGroup, storeName, path)
		return ok, nil
	}
	return ok, err
}

func (fs *FileWalkSvc) forcePostWalkPathEvent(storeName string, userGroup string, path string) error {
	flag := fs.keyWalkFlag(storeName, path)
	_, err := cache.SetExpire(flag, time.Now().String(), cache.DefaultExpireTime)
	if err != nil {
		return err
	}
	fileWalker.postWalkEvent(userGroup, storeName, path)
	return nil
}

var fileWalker *fileWalk

type walkEvent struct {
	userGroup string
	storeName string
	path      string
}

type fileWalk struct {
	eventQueue chan *walkEvent
}

func init() {
	fileWalker = &fileWalk{
		eventQueue: make(chan *walkEvent, 1024),
	}
	for i := 0; i < 10; i++ {
		go fileWalker.processEvent(i)
	}
}

func (fw *fileWalk) postWalkEvent(group string, storeName string, path string) {
	fw.eventQueue <- &walkEvent{
		userGroup: group,
		storeName: storeName,
		path:      path,
	}
}

func (fw *fileWalk) processEvent(index int) {
	logger.Info("start file walk processor", index)
	for true {
		event := <-fw.eventQueue
		fw.handle(event)
	}
}

func (fw *fileWalk) handle(event *walkEvent) {
	files, err := vfs.List(event.userGroup, event.path)
	if err != nil {
		return
	}
	thumbSvc.BatchThumbnail(files)
	for _, item := range files {
		if item.Hidden {
			continue
		}
		fw.saveObjectInfo(event.storeName, event.path, item)
		fw.saveToNameRank(event.storeName, event.path, item)
		fw.saveToSizeRank(event.storeName, event.path, item)
		fw.saveToTimeRank(event.storeName, event.path, item)
	}
}

func (fw *fileWalk) saveObjectInfo(storeName string, path string, item *vfs.ObjectInfo) {
	data, er := json.Marshal(item)
	if er != nil {
		return
	}
	key := fileWalkSvc.keyItem(storeName, path, item.Name)
	state, er := cache.Set(key, string(data))
	if er != nil {
		logger.Error("SAVE_CACHE_ERROR", key, string(data), state, er)
	} else {
		logger.Info("SAVE_CACHE", key, state)
	}
}

func (fw *fileWalk) saveToNameRank(storeName string, path string, item *vfs.ObjectInfo) {
	key := fileWalkSvc.keyRank(storeName, path, "fileName")
	_, err := cache.ZAdd(key, libs.If(item.Type == vfs.ObjectTypeDir, float64(50), float64(100)).(float64), item.Name)
	if err != nil {
		logger.Error("saveToNameRank error", key, item.Name, err)
	}
}

func (fw *fileWalk) saveToSizeRank(storeName string, path string, item *vfs.ObjectInfo) {
	key := fileWalkSvc.keyRank(storeName, path, "size")
	_, err := cache.ZAdd(key, libs.If(item.Type == vfs.ObjectTypeDir, float64(0), float64(item.Size)).(float64), item.Name)
	if err != nil {
		logger.Error("saveToSizeRank error", key, item.Name, err)
	}
}

func (fw *fileWalk) saveToTimeRank(storeName string, path string, item *vfs.ObjectInfo) {
	key := fileWalkSvc.keyRank(storeName, path, "time")
	var score float64 = 0
	if item.CreTime != nil {
		str := item.CreTime.Format("20060102150405")
		val, _ := strconv.Atoi(str)
		score = float64(val)
	} else if item.ModTime != nil {
		str := item.ModTime.Format("20060102150405")
		val, _ := strconv.Atoi(str)
		score = float64(val)
	}
	_, err := cache.ZAdd(key, score, item.Name)
	if err != nil {
		logger.Error("saveToTimeRank error", key, item.Name, err)
	}
}
