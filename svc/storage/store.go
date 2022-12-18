package storage

import "time"

type ObjectType string

const (
	ObjectTypeFile ObjectType = "FILE"
	ObjectTypeDir  ObjectType = "DIR"
	ObjectTypeExt  ObjectType = "EXT"
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

type store interface {
	list(fullPath string) []*ObjectInfo

	info(fullPath string) *ObjectInfo
}

func emptyObjectInfos() []*ObjectInfo {
	return []*ObjectInfo{}
}
