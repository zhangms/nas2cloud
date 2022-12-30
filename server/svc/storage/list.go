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

type FileListSvc struct {
}

func (fs *FileListSvc) List(username string, fullPath string, orderBy string, start int64, stop int64) (files []*vfs.ObjectInfo, total int64, err error) {
	userGroup := user.GetUserGroup(username)
	path := filepath.Clean(fullPath)
	if vfs.IsRoot(path) {
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

func (fs *FileListSvc) unmarshal(arr []any) []*vfs.ObjectInfo {
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

func (fs *FileListSvc) getFromCache(storeName string, path string, orderBy string, start int64, stop int64) ([]any, int64, error) {
	sort := strings.SplitN(orderBy, "_", 2)
	key := cache.Join(storeName, path, "order", sort[0])
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
	arr, err := cache.MGet(list...)
	return arr, total, nil
}

func (fs *FileListSvc) tryPostWalkPathEvent(storeName string, userGroup string, path string) (bool, error) {
	keyInfo := cache.Join(storeName, path, "info")
	ok, err := cache.SetNXExpire(keyInfo, time.Now().String(), cache.DefaultExpireTime)
	if ok {
		fileWalker.postWalkEvent(userGroup, storeName, path)
		return ok, nil
	}
	return ok, err
}

var fileListSvc = &FileListSvc{}

func FileList() *FileListSvc {
	return fileListSvc
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
		fw.saveObjectInfo(event.storeName, item)
		fw.saveToNameRank(event.storeName, event.path, item)
		fw.saveToSizeRank(event.storeName, event.path, item)
		fw.saveToTimeRank(event.storeName, event.path, item)
	}
}

func (fw *fileWalk) saveObjectInfo(storeName string, item *vfs.ObjectInfo) {
	data, er := json.Marshal(item)
	if er != nil {
		return
	}
	keyFile := cache.Join(storeName, item.Path)
	state, er := cache.Set(keyFile, string(data))
	if er != nil {
		logger.Error("SAVE_CACHE_ERROR", keyFile, string(data), state, er)
	} else {
		logger.Info("SAVE_CACHE", keyFile, state)
	}
}

func (fw *fileWalk) saveToNameRank(storeName string, path string, item *vfs.ObjectInfo) {
	key := cache.Join(storeName, path, "order", "fileName")
	keyInfo := cache.Join(storeName, item.Path)
	_, err := cache.ZAdd(key, libs.If(item.Type == vfs.ObjectTypeDir, float64(50), float64(100)).(float64), keyInfo)
	if err != nil {
		logger.Error("saveToNameRank error", key, keyInfo, err)
	}
}

func (fw *fileWalk) saveToSizeRank(storeName string, path string, item *vfs.ObjectInfo) {
	key := cache.Join(storeName, path, "order", "size")
	keyInfo := cache.Join(storeName, item.Path)
	_, err := cache.ZAdd(key, libs.If(item.Type == vfs.ObjectTypeDir, float64(0), float64(item.Size)).(float64), keyInfo)
	if err != nil {
		logger.Error("saveToSizeRank error", key, keyInfo, err)
	}
}

func (fw *fileWalk) saveToTimeRank(storeName string, path string, item *vfs.ObjectInfo) {
	key := cache.Join(storeName, path, "order", "time")
	keyInfo := cache.Join(storeName, item.Path)
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
	_, err := cache.ZAdd(key, score, keyInfo)
	if err != nil {
		logger.Error("saveToTimeRank error", key, keyInfo, err)
	}
}
