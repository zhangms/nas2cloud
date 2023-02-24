package files

import (
	"context"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"time"
)

var walk *walker

func startWalker(ctx context.Context) {
	walk = &walker{
		ctx: ctx,
	}
	go walk.run()
}

type walker struct {
	ctx context.Context
}

func (w *walker) run() {
	timer := time.NewTimer(time.Second * 5)
	select {
	case <-w.ctx.Done():
		logger.Info("walker stopped")
		return
	case <-timer.C:
		w.execute("/")
	}
}

func (w *walker) execute(path string) {
	items, err := vfs.List(sysUser, path)
	if err != nil {
		logger.Error("execute walk error", path, err)
		return
	}
	for _, item := range items {
		if item.Type != vfs.ObjectTypeDir || walkIgnore(item) {
			continue
		}
		w.execute(item.Path)
		exists, er := repo.exists(item.Path)
		if er != nil {
			logger.Error("execute walk error, repo exists", path, er)
		}
		if !exists {
			ok, _ := evt.tryFireWalk(&event{
				eventType: eventWalk,
				userName:  sysUser,
				userRoles: sysUser,
				path:      item.Path,
			})
			if ok {
				logger.Info("execute walk", item.Path)
			}
		}
	}
}
