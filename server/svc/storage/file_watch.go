package storage

import (
	"errors"
	"nas2cloud/libs/errs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc/cache"
	"time"
)

type fileWatchSvc struct {
	eventQueue chan *fileEvent
}

var fileWatcher *fileWatchSvc

type fileEventType string

const (
	eventWalk   fileEventType = "walk"
	eventCreate fileEventType = "create"
	eventDelete fileEventType = "createDelete"
)

type fileEvent struct {
	eventType fileEventType
	userGroup string
	storeName string
	path      string
}

func init() {
	fileWatcher = &fileWatchSvc{
		eventQueue: make(chan *fileEvent, 1024),
	}
	for i := 0; i < 10; i++ {
		go fileWatcher.process(i)
	}
}

func (fw *fileWatchSvc) fireEvent(event *fileEvent) {
	if event != nil {
		fw.eventQueue <- event
	}
}

func (fw *fileWatchSvc) process(index int) {
	logger.Info("start file watch processor", index)
	for true {
		event := <-fw.eventQueue
		err := fw.processEvent(event)
		if err != nil {
			logger.Error("process event error", event, err)
		}
	}
}

func (fw *fileWatchSvc) processEvent(event *fileEvent) error {
	defer func() {
		err := recover()
		if err != nil {
			logger.Error("process event error recover", err)
		}
	}()
	switch event.eventType {
	case eventWalk:
		return fw.processWalk(event)
	case eventCreate:
		return fw.processCreate(event)
	case eventDelete:
		return fw.processDelete(event)
	default:
		return errors.New("unknown event type:" + string(event.eventType))
	}
}

func (fw *fileWatchSvc) processWalk(event *fileEvent) error {
	files, err := vfs.List(event.userGroup, event.path)
	if err != nil {
		return err
	}
	thumbSvc.BatchThumbnail(files)
	for _, item := range files {
		if item.Hidden {
			continue
		}
		err = fileRepo.save(item)
		if err != nil {
			return errs.Wrap(err, "save item error:"+item.Path)
		}
	}
	return nil
}

func (fw *fileWatchSvc) processCreate(event *fileEvent) error {
	return nil
}

func (fw *fileWatchSvc) processDelete(event *fileEvent) error {
	return nil
}

func (fw *fileWatchSvc) tryFireWalkEvent(event *fileEvent) (bool, error) {
	flag := fw.keyWalkFlag(event.storeName, event.path)
	ok, err := cache.SetNXExpire(flag, time.Now().String(), cache.DefaultExpireTime)
	if ok {
		fw.fireEvent(event)
		return ok, nil
	}
	return ok, err
}

func (fw *fileWatchSvc) keyWalkFlag(storeName string, path string) string {
	return cache.Join(storeName, fileRepo.version, "walk_flag", path)
}
