package storage

import (
	"errors"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

type diskUsage struct {
}

type pathSize struct {
	path string
	size int64
}

var disk = &diskUsage{}

func (d *diskUsage) duAllParent(path string) ([]*pathSize, error) {
	bucket, file, err := vfs.GetBucket(sysUser, path)
	if err != nil {
		return nil, err
	}
	if !bucket.MountTypeLocal() {
		return nil, errors.New("du not support :" + bucket.MountType())
	}
	base := filepath.Clean(bucket.Endpoint())
	absPath := filepath.Join(base, file)
	ret := make([]*pathSize, 0)
	for {
		size := d.du(absPath)
		ret = append(ret, &pathSize{
			size: size,
			path: filepath.Join(bucket.Dir(), absPath[len(base):]),
		})
		absPath = filepath.Dir(absPath)
		if len(absPath) < len(base) {
			break
		}
	}
	return ret, nil
}

func (d *diskUsage) du(local string) (size int64) {

	start := time.Now()
	defer func() {
		end := time.Now()
		err := recover()
		if err != nil {
			logger.Error("du error", local, "rt", end.Sub(start).Milliseconds(), "(ms)", err)
		} else {
			logger.Info("du ", local, libs.ReadableDataSize(size), "rt", end.Sub(start).Milliseconds(), "(ms)")
		}
	}()
	cmd := exec.Command("du", "-sk", local)
	data, err := cmd.Output()
	if err != nil {
		panic(err)
	}
	sp := strings.SplitN(string(data), string(rune(9)), 2)
	sizei, err := strconv.Atoi(strings.TrimSpace(sp[0]))
	if err != nil {
		panic(err)
	}
	size = int64(sizei) * 1024
	return
}
