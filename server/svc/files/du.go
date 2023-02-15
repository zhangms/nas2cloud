package files

import (
	"context"
	"errors"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/libs/vfs/vpath"
	"nas2cloud/res"
	"nas2cloud/svc/cache"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"
)

type diskUsage struct {
	queue chan string
}

type pathSize struct {
	path string
	size int64
}

var du *diskUsage

func startDiskUsage(ctx context.Context) {
	du = &diskUsage{
		queue: make(chan string, 1024),
	}
	count := res.GetInt("processor.count.diskusage", 1)
	for i := 0; i < count; i++ {
		go du.process(i, ctx)
	}
}

func (d *diskUsage) post(path string) {
	d.queue <- path
}

func (d *diskUsage) process(index int, ctx context.Context) {
	logger.Info("diskUsage process started", index)
	for {
		select {
		case <-ctx.Done():
			logger.Info("diskUsage process stopped", index)
			return
		case path := <-d.queue:
			list, err := d.duAllParent(path)
			if err != nil {
				logger.Error("process du error", path, err)
				continue
			}
			for _, ps := range list {
				if er := fileCache.updateSize(sysUser, ps.path, ps.size); er != nil {
					logger.Error("update size error", ps.path, er)
				}
			}
		}
	}
}

func (d *diskUsage) duAllParent(path string) ([]*pathSize, error) {
	start := time.Now()
	ret := make([]*pathSize, 0)
	defer func() {
		end := time.Now()
		logger.Info("duAllParent : ", "rt", end.Sub(start).Milliseconds(), "(ms)", path, "resultSize", len(ret))
	}()
	bucket, file, err := vfs.GetBucket(sysUser, path)
	if err != nil {
		return nil, err
	}
	if !bucket.MountTypeLocal() {
		return nil, errors.New("du not support:" + path + ";" + bucket.MountType())
	}
	base := filepath.Clean(bucket.Endpoint())
	localPath := filepath.Join(base, file)
	for len(localPath) >= len(base) {
		ok, _ := cache.SetNXExpire("diskUsage:"+localPath, time.Now().String(), cache.DefaultExpireTime)
		if ok {
			vfsPath := vpath.Join(bucket.Dir(), localPath[len(base):])
			size := d.du(localPath)
			if size > 0 {
				ret = append(ret, &pathSize{
					path: vfsPath,
					size: size,
				})
			}
		}
		tmp := filepath.Dir(localPath)
		if tmp == localPath {
			break
		} else {
			localPath = tmp
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
