package vfs

import (
	"io"
	"io/fs"
	"io/ioutil"
	"nas2cloud/libs"
	"nas2cloud/libs/errs"
	"os"
	"path"
	"path/filepath"
	"strings"
)

type Local struct {
	bucket *Bucket
}

// AbsLocal 本地文件的绝对路径
func (l *Local) AbsLocal(file string) string {
	if l.bucket != nil {
		return path.Join(l.bucket.endpoint, file)
	}
	p, _ := filepath.Abs(file)
	return p
}

// AbsVirtual vfs中的绝对路径
func (l *Local) AbsVirtual(file string) string {
	if l.bucket != nil {
		return path.Join(l.bucket.Dir(), file)
	}
	p, _ := filepath.Abs(file)
	return p
}

func (l *Local) Name() string {
	return l.bucket.name
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

func (l *Local) Read(file string) ([]byte, error) {
	return ioutil.ReadFile(l.AbsLocal(file))
}

func (l *Local) Write(file string, data []byte) error {
	return ioutil.WriteFile(l.AbsLocal(file), data, fs.ModePerm)
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

func (l *Local) Upload(file string, reader io.Reader) (int64, error) {
	f, err := os.OpenFile(l.AbsLocal(file), os.O_CREATE|os.O_WRONLY|os.O_SYNC, fs.ModePerm)
	defer func() {
		_ = f.Close()
	}()
	if err != nil {
		return 0, err
	}
	var read int64 = 0
	for {
		buffer := make([]byte, 4096)
		n, readErr := reader.Read(buffer)
		read += int64(n)
		if n > 0 {
			_, writeErr := f.Write(buffer[0:n])
			if writeErr != nil {
				return read, errs.Wrap(writeErr, "write error:"+file)
			}
		} else {
			break
		}
		if readErr == io.EOF {
			return read, nil
		}
		if readErr != nil {
			return read, errs.Wrap(readErr, "read error")
		}
	}
	return read, nil
}

func (l *Local) infoF(fullPath string, fi os.FileInfo) (*ObjectInfo, error) {
	modTime := fi.ModTime()
	return &ObjectInfo{
		Name:    libs.If(fullPath == l.bucket.Dir(), l.bucket.name, fi.Name()).(string),
		Path:    fullPath,
		Type:    libs.If(fi.IsDir(), ObjectTypeDir, ObjectTypeFile).(ObjectType),
		Hidden:  strings.Index(fi.Name(), ".") == 0,
		ModTime: &modTime,
		Size:    fi.Size(),
		Ext:     strings.ToUpper(filepath.Ext(fi.Name())),
	}, nil
}
