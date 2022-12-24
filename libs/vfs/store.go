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
}

type Store interface {
	List(file string) ([]*ObjectInfo, error)

	Info(file string) (*ObjectInfo, error)

	Read(file string) ([]byte, error)

	Write(file string, data []byte) error
}
