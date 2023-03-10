package vfs

import (
	"io"
	"time"
)

type ObjectType string

const (
	ObjectTypeFile ObjectType = "FILE"
	ObjectTypeDir  ObjectType = "DIR"
	ObjectTypeLink ObjectType = "LINK"
)

type ObjectInfo struct {
	Name    string
	Path    string
	Type    ObjectType
	Hidden  bool
	CreTime int64
	ModTime int64
	MD5Sum  string
	Preview string
	Size    int64
	Ext     string
}

type Store interface {
	Name() string

	List(file string) ([]*ObjectInfo, error)

	Info(file string) (*ObjectInfo, error)

	Open(file string) (io.Reader, error)

	Read(file string) ([]byte, error)

	Write(file string, data []byte) error

	Exists(file string) bool

	MkdirAll(file string) error

	RemoveAll(file string) error

	Remove(file string) error

	IsWriteable() bool

	Upload(file string, reader io.Reader, modTime time.Time) (int64, error)
}
