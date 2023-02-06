package vfs

import (
	"io"
	"io/fs"
	"nas2cloud/libs"
	"nas2cloud/libs/vfs/vpath"
	"os"
	"path"
	"path/filepath"
	"strings"
	"time"
)

type Local struct {
	bucket *Bucket
}

// AbsLocal 本地文件的绝对路径
func (l *Local) AbsLocal(file string) string {
	if l.bucket != nil {
		return filepath.Join(l.bucket.endpoint, file)
	}
	p, _ := filepath.Abs(file)
	return p
}

// AbsVirtual vfs中的绝对路径
func (l *Local) AbsVirtual(file string) string {
	if l.bucket != nil {
		return vpath.Join(l.bucket.Dir(), file)
	}
	p, _ := filepath.Abs(file)
	return p
}

func (l *Local) Name() string {
	return l.bucket.id
}

func (l *Local) List(file string) ([]*ObjectInfo, error) {
	info, err := l.Info(file)
	if err != nil {
		return nil, err
	}
	if info.Type != ObjectTypeDir {
		return []*ObjectInfo{}, nil
	}
	entries, err := os.ReadDir(l.AbsLocal(file))
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
		inf, er := l.infoF(path.Join(l.AbsVirtual(file), fi.Name()), fi)
		if er != nil {
			continue
		}
		ret = append(ret, inf)
	}
	return ret, nil
}

func (l *Local) Info(file string) (*ObjectInfo, error) {
	fi, err := os.Stat(l.AbsLocal(file))
	if err != nil {
		return nil, err
	}
	return l.infoF(l.AbsVirtual(file), fi)
}

func (l *Local) Open(file string) (io.Reader, error) {
	return os.Open(l.AbsLocal(file))
}

func (l *Local) Read(file string) ([]byte, error) {
	return os.ReadFile(l.AbsLocal(file))
}

func (l *Local) IsWriteable() bool {
	return IsModeWriteable(l.bucket.mode)
}

func (l *Local) Write(file string, data []byte) error {
	return os.WriteFile(l.AbsLocal(file), data, fs.ModePerm)
}

func (l *Local) Exists(file string) bool {
	_, err := os.Stat(l.AbsLocal(file))
	if err != nil {
		return os.IsExist(err)
	}
	return true
}

func (l *Local) MkdirAll(file string) error {
	return os.MkdirAll(l.AbsLocal(file), fs.ModePerm)
}

func (l *Local) RemoveAll(file string) error {
	return os.RemoveAll(l.AbsLocal(file))
}

func (l *Local) Remove(file string) error {
	err := os.Remove(l.AbsLocal(file))
	if err != nil {
		if l.Exists(file) {
			return err
		}
	}
	return nil
}

func (l *Local) Upload(file string, reader io.Reader, modTime time.Time) (int64, error) {
	l.MkdirAll(filepath.Dir(file))
	writer, err := os.OpenFile(l.AbsLocal(file), os.O_CREATE|os.O_WRONLY, fs.ModePerm)
	if err != nil {
		return 0, err
	}
	defer func() {
		_ = writer.Close()
	}()
	written, err := io.Copy(writer, reader)
	if err != nil {
		return written, err
	}
	_ = writer.Close()
	_ = os.Chtimes(l.AbsLocal(file), modTime, modTime)
	return written, nil
}

func (l *Local) infoF(fullPath string, fi os.FileInfo) (*ObjectInfo, error) {
	modTime := fi.ModTime()
	return &ObjectInfo{
		Name:    libs.If(fullPath == l.bucket.Dir(), l.bucket.name, fi.Name()).(string),
		Path:    fullPath,
		Type:    libs.If(fi.IsDir(), ObjectTypeDir, ObjectTypeFile).(ObjectType),
		Hidden:  strings.Index(fi.Name(), ".") == 0,
		ModTime: modTime,
		CreTime: modTime,
		Size:    fi.Size(),
		Ext:     strings.ToUpper(filepath.Ext(fi.Name())),
	}, nil
}
