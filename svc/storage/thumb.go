package storage

import (
	"nas2cloud/svc/storage/store"
	"strings"
)

const thumbnailDir = "external:/__thumb__"

func thumbnail(obj *store.ObjectInfo) {
	batchThumbnail([]*store.ObjectInfo{obj})
}

func batchThumbnail(infos []*store.ObjectInfo) {
	for _, inf := range infos {
		if inf.Type != store.ObjectTypeFile {
			continue
		}
		arr := strings.Split(inf.Name, ".")
		if len(arr) < 2 {
			continue
		}
		suffix := strings.ToUpper(arr[len(arr)-1])
		switch suffix {
		case "JPG", "JPEG", "PNG":

		}
	}
}
