package storage

import "time"

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
	CreTime *time.Time
	ModTime *time.Time
	MD5Sum  string
	Preview string
	Size    int64
}

type Store interface {
	List(path string) []*ObjectInfo
}
