package files

import (
	"context"
	"errors"
	"nas2cloud/libs/errs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/res"
)

type watcher struct {
	eventQueue chan *fileEvent
}

var watch *watcher

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

func startWatcher(ctx context.Context) {
	watch = &watcher{
		eventQueue: make(chan *fileEvent, 1024),
	}
	count := res.GetInt("processor.count.filewatch", 1)
	for i := 0; i < count; i++ {
		go watch.process(i, ctx)
	}
}

func (fw *watcher) fireEvent(event *fileEvent) {
	if event != nil {
		fw.eventQueue <- event
	}
}

func (fw *watcher) process(index int, ctx context.Context) {
	logger.Info("file watch processor started", index)
	for {
		select {
		case <-ctx.Done():
			logger.Info("file watch processor stopped", index)
			return
		case event := <-fw.eventQueue:
			if err := fw.processEvent(event); err != nil {
				logger.Error("process event error", event, err)
			}
		}
	}
}

func (fw *watcher) processEvent(event *fileEvent) error {
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

func (fw *watcher) processWalk(event *fileEvent) error {
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
	thumb.posts(files)
	du.post(event.path)
	return nil
}

func (fw *watcher) processCreate(event *fileEvent) error {
	info, err := vfs.Info(event.userRoles, event.path)
	if err != nil {
		return err
	}
	thumb.post(info)
	du.post(event.path)
	return nil
}

func (fw *watcher) processDelete(event *fileEvent) error {
	du.post(event.path)
	return nil
}

func (fw *watcher) tryFireWalkEvent(event *fileEvent) (bool, error) {
	ok, err := fileCache.walkFlag(event.path)
	if ok {
		fw.fireEvent(event)
		return ok, nil
	}
	return ok, err
}
