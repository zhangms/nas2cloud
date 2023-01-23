package storage

import (
	"errors"
	"nas2cloud/env"
	"nas2cloud/libs"
	"nas2cloud/libs/errs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
)

type fileWatchSvc struct {
	eventQueue chan *fileEvent
}

var fileWatcher *fileWatchSvc

type fileEventType string

const (
	eventWalk   fileEventType = "walk"
	eventCreate fileEventType = "create"
	eventDelete fileEventType = "delete"
)

type fileEvent struct {
	eventType fileEventType
	userName  string
	userRoles string
	path      string
}

func init() {
	if !env.IsActionStart() {
		return
	}
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
	for {
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
	info, err := vfs.Info(event.userRoles, event.path)
	if err != nil {
		return err
	}
	err = fileCache.saveIfAbsent(info)
	if err != nil {
		return err
	}
	files, err := vfs.List(event.userRoles, event.path)
	if err != nil {
		return err
	}
	for _, item := range files {
		if item.Hidden {
			continue
		}
		err = fileCache.saveIfAbsent(item)
		if err != nil {
			return errs.Wrap(err, "save item error:"+item.Path)
		}
	}
	fw.diskUsage(event.path)
	return nil
}

func (fw *fileWatchSvc) processCreate(event *fileEvent) error {
	fw.diskUsage(event.path)
	return nil
}

func (fw *fileWatchSvc) processDelete(event *fileEvent) error {
	fw.diskUsage(event.path)
	return nil
}

func (fw *fileWatchSvc) tryFireWalkEvent(event *fileEvent) (bool, error) {
	ok, err := fileCache.walkFlag(event.path)
	if ok {
		fw.fireEvent(event)
		return ok, nil
	}
	return ok, err
}

func (fw *fileWatchSvc) diskUsage(path string) {
	usage, err := disk.duAllParent(path)
	if err != nil {
		logger.Error("DU_EXEC_ERROR", path, err)
		return
	}
	for _, du := range usage {
		err = fileCache.updateSize(du.path, du.size)
		if err != nil {
			logger.Error("DU_UPDATE_FILE_SIZE_ERROR", du.path, err)
		} else {
			logger.Info("DU_UPDATE_FILE_SIZE", du.path, libs.ReadableDataSize(du.size))
		}
	}
}
