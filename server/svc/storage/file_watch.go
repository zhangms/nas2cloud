package storage

import (
	"errors"
	"nas2cloud/conf"
	"nas2cloud/env"
	"nas2cloud/libs/errs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"sync/atomic"
	"time"
)

type fileWatchSvc struct {
	fileEventQueue chan *fileEvent
	diskUsageQueue chan string
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
		fileEventQueue: make(chan *fileEvent, 1024),
		diskUsageQueue: make(chan string, 1024),
	}
	processor := conf.GetInt("processor.count.filewatch", 1)
	for i := 0; i < processor; i++ {
		go fileWatcher.process(i)
	}
}

func (fw *fileWatchSvc) fireEvent(event *fileEvent) {
	if event != nil {
		fw.fileEventQueue <- event
	}
}

func (fw *fileWatchSvc) process(index int) {
	logger.Info("start file watch processor", index)
	paths := make([]string, 0)
	duExecuting := &atomic.Bool{}
	duExecuting.Store(false)
	for {
		select {
		case event := <-fw.fileEventQueue:
			err := fw.processEvent(event)
			if err != nil {
				logger.Error("process event error", event, err)
			}
		case filepath := <-fw.diskUsageQueue:
			paths = append(paths, filepath)
		default:
			if len(paths) == 0 {
				time.Sleep(time.Millisecond * 10)
				continue
			}
			if !duExecuting.CompareAndSwap(false, true) {
				time.Sleep(time.Millisecond * 10)
				continue
			}
			tmp := paths
			paths = make([]string, 0)
			go func() {
				defer duExecuting.Store(false)
				fw.diskUsageExec(tmp)
			}()
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
	if len(path) > 0 {
		fw.diskUsageQueue <- path
	}
}

func (fw *fileWatchSvc) diskUsageExec(paths []string) {
	usage, err := disk.duAllParent(paths)
	if err != nil {
		logger.Error("DU_EXEC_ERROR", paths, err)
		return
	}
	for _, du := range usage {
		err = fileCache.updateSize(sysUser, du.path, du.size)
		if err != nil {
			logger.Error("DU_UPDATE_FILE_SIZE_ERROR", du.path, err)
		}
	}
}
