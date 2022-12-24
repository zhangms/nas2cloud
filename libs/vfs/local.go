package vfs

import (
	"io/fs"
	"io/ioutil"
	"nas2cloud/libs"
	"os"
	"path"
	"strings"
)

type vLocal struct {
	bucket *bucket
}

//本地文件的绝对路径
func (l *vLocal) rAbs(file string) string {
	return path.Join(l.bucket.endpoint, file)
}

//vfs中的绝对路径
func (l *vLocal) vAbs(file string) string {
	return path.Join(l.bucket.dir(), file)
}

func (l *vLocal) List(file string) ([]*ObjectInfo, error) {
	info, err := l.Info(file)
	if err != nil {
		return nil, err
	}
	if info.Type != ObjectTypeDir {
		return []*ObjectInfo{}, nil
	}
	entries, err := os.ReadDir(l.rAbs(file))
	if err != nil {
		return nil, err
	}
	ret := make([]*ObjectInfo, 0)
	for _, entry := range entries {
		fi, er := entry.Info()
		if er != nil {
			continue
		}
		if fi.Name() == "$RECYCLE.BIN" {
			continue
		}
		inf, er := l.infoF(path.Join(l.vAbs(file), fi.Name()), fi)
		if er != nil {
			continue
		}
		ret = append(ret, inf)
	}
	return ret, nil
}

func (l *vLocal) Info(file string) (*ObjectInfo, error) {
	fi, err := os.Stat(l.rAbs(file))
	if err != nil {
		return nil, err
	}
	return l.infoF(l.vAbs(file), fi)
}

func (l *vLocal) Read(file string) ([]byte, error) {
	return ioutil.ReadFile(l.rAbs(file))
}

func (l *vLocal) Write(file string, data []byte) error {
	return ioutil.WriteFile(l.rAbs(file), data, fs.ModePerm)
}

func (l *vLocal) infoF(fullPath string, fi os.FileInfo) (*ObjectInfo, error) {
	modTime := fi.ModTime()
	return &ObjectInfo{
		Name:    libs.If(fullPath == l.bucket.dir(), l.bucket.name, fi.Name()).(string),
		Path:    fullPath,
		Type:    libs.If(fi.IsDir(), ObjectTypeDir, ObjectTypeFile).(ObjectType),
		Hidden:  strings.Index(fi.Name(), ".") == 0,
		ModTime: &modTime,
		Size:    fi.Size(),
	}, nil
}
