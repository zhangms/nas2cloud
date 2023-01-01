package vfs

import "time"

type ObjectType string

const (
	ObjectTypeFile ObjectType = "FILE"
	ObjectTypeDir  ObjectType = "DIR"
)

type ObjectInfo struct {
	Name    string
	Path    string
	Type    ObjectType
	Hidden  bool
	CreTime *time.Time
	ModTime *time.Time
	MD5Sum  string
	Preview string
	Size    int64
	Ext     string
}

type Store interface {
	Name() string

	List(file string) ([]*ObjectInfo, error)

	Info(file string) (*ObjectInfo, error)

	Read(file string) ([]byte, error)

	Write(file string, data []byte) error

	Exists(file string) bool

	CreateDirAll(file string) error
}
