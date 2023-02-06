package storage

import (
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/libs/vfs/vpath"
	"nas2cloud/svc/cache"
	"os/exec"
	"path/filepath"
	"runtime"
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

func (d *diskUsage) duAllParent(paths []string) ([]*pathSize, error) {
	start := time.Now()
	ret := make([]*pathSize, 0)
	defer func() {
		end := time.Now()
		logger.Info("duAllParent : ", "rt", end.Sub(start).Milliseconds(), "(ms)", len(paths), paths, "resultSize", len(ret))
	}()
	group := make(map[string]*pathSize)
	localPaths := make([]string, 0)
	for _, path := range paths {
		bucket, file, err := vfs.GetBucket(sysUser, path)
		if err != nil {
			logger.Error("duAllParent error", path, err)
			continue
		}
		if !bucket.MountTypeLocal() {
			logger.Error("du not support", path, bucket.MountType())
			continue
		}
		base := filepath.Clean(bucket.Endpoint())
		localPath := filepath.Join(base, file)
		for {
			_, ok := group[localPath]
			if ok {
				continue
			}
			group[localPath] = &pathSize{
				size: 0,
				path: vpath.Join(bucket.Dir(), localPath[len(base):]),
			}
			localPaths = append(localPaths, localPath)
			localPath = filepath.Dir(localPath)
			if len(localPath) < len(base) {
				break
			}
		}
	}
	for _, localPath := range localPaths {
		ps := group[localPath]
		ok, _ := cache.SetNXExpire("diskUsage:"+localPath, ps.path+";"+time.Now().String(), cache.DefaultExpireTime)
		if !ok {
			continue
		}
		size := d.du(localPath)
		if size > 0 {
			ps.size = size
			ret = append(ret, ps)
		}
	}
	return ret, nil
}

func (d *diskUsage) du(local string) (size int64) {
	start := time.Now()
	size = 0
	defer func() {
		end := time.Now()
		err := recover()
		if err != nil {
			size = 0
			logger.Error("du error", local, "rt", end.Sub(start).Milliseconds(), "(ms)", err)
		} else {
			logger.Info("du ", local, libs.ReadableDataSize(size), "rt", end.Sub(start).Milliseconds(), "(ms)")
		}
	}()
	if runtime.GOOS == "windows" {
		size = d.duWindows(local)
	} else {
		size = d.duLinux(local)
	}
	return
}

func (d *diskUsage) duWindows(local string) int64 {
	cmd := exec.Command("du", local)
	data, err := cmd.Output()
	if err != nil {
		panic(err)
	}
	arr := strings.Split(strings.TrimSpace(string(data)), "\n")
	size := strings.TrimSpace(arr[len(arr)-1])
	size = strings.TrimSpace(strings.Split(size, ":")[1])
	size = strings.TrimSpace(strings.Split(size, " ")[0])
	size = strings.ReplaceAll(size, ",", "")
	sizei, err := strconv.Atoi(size)
	if err != nil {
		logger.Error("windows du output", string(data))
		panic(err)
	}
	return int64(sizei)
}

func (d *diskUsage) duLinux(local string) int64 {
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
	return int64(sizei) * 1024
}
