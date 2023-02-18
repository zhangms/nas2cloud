package files

import (
	"context"
	"errors"
	"nas2cloud/libs/errs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/libs/vfs/vpath"
	"nas2cloud/res"
	"nas2cloud/svc/cache"
	"time"
)

type eventProcessor struct {
	queue chan *event
}

var evt *eventProcessor

type eventType string

const (
	eventWalk   eventType = "walk"
	eventCreate eventType = "create"
	eventDelete eventType = "delete"
)

type event struct {
	eventType eventType
	userName  string
	userRoles string
	path      string
}

func startEventProcessor(ctx context.Context) {
	evt = &eventProcessor{
		queue: make(chan *event, 1024),
	}
	count := res.GetInt("processor.count.file.event", 1)
	for i := 0; i < count; i++ {
		go evt.process(i, ctx)
	}
}

func (ep *eventProcessor) fire(event *event) {
	if event != nil {
		ep.queue <- event
	}
}

func (ep *eventProcessor) process(index int, ctx context.Context) {
	logger.Info("file evt processor started", index)
	for {
		select {
		case <-ctx.Done():
			logger.Info("file evt processor stopped", index)
			return
		case event := <-ep.queue:
			if err := ep.processEvent(event); err != nil {
				logger.Error("process event error", event, err)
			}
		}
	}
}

func (ep *eventProcessor) processEvent(event *event) error {
	defer func() {
		err := recover()
		if err != nil {
			logger.Error("process event error recover", err)
		}
	}()
	switch event.eventType {
	case eventWalk:
		return ep.processWalk(event)
	case eventCreate:
		return ep.processCreate(event)
	case eventDelete:
		return ep.processDelete(event)
	default:
		return errors.New("unknown event type:" + string(event.eventType))
	}
}

func (ep *eventProcessor) processWalk(event *event) error {
	info, err := vfs.Info(event.userRoles, event.path)
	if err != nil {
		return err
	}
	err = repo.saveIfAbsent(info)
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
		err = repo.saveIfAbsent(item)
		if err != nil {
			return errs.Wrap(err, "save item error:"+item.Path)
		}
	}
	if err = repo.save(info); err != nil {
		return errs.Wrap(err, "save item error:"+info.Path)
	}
	thumbExecutor.posts(files)
	du.post(event.path)
	return nil
}

func (ep *eventProcessor) processCreate(event *event) error {
	info, err := vfs.Info(event.userRoles, event.path)
	if err != nil {
		return err
	}
	thumbExecutor.post(info)
	du.post(event.path)
	return nil
}

func (ep *eventProcessor) processDelete(event *event) error {
	du.post(event.path)
	return nil
}

func (ep *eventProcessor) tryFireWalk(event *event) (bool, error) {
	cp := vpath.Clean(event.path)
	bucket, _ := vpath.BucketFile(cp)
	key := cache.Join(bucket, "walk_flag", cp)
	ok, err := cache.SetNXExpire(key, time.Now().String(), cache.DefaultExpireTime)
	if ok {
		ep.fire(event)
		return ok, nil
	}
	return ok, err
}
