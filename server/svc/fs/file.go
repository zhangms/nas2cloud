package fs

import (
	"io/fs"
	"nas2cloud/libs/vfs"
	"os"
	"sync"
)

const sysUser = "root"

func AppName() string {
	return "nas2cloud"
}

func GetTempDir() string {
	dir := "." + AppName() + "/temp"
	_ = os.MkdirAll(dir, fs.ModePerm)
	return dir
}

var initOnce = &sync.Once{}

func DoInit(env string) {
	initOnce.Do(func() {
		vfs.Load(env)
		startWatcher()
		startThumbnails()
	})
}
