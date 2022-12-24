package storage

import (
	"nas2cloud/libs/vfs"
)

const thumbnailDir = "external:/__thumb__"

func thumbnail(obj *vfs.ObjectInfo) {
}

func batchThumbnail(infos []*vfs.ObjectInfo) {
	//for _, inf := range infos {
	//	if inf.Type != store.ObjectTypeFile {
	//		continue
	//	}
	//	arr := strings.Split(inf.Name, ".")
	//	if len(arr) < 2 {
	//		continue
	//	}
	//	suffix := strings.ToUpper(arr[len(arr)-1])
	//	switch suffix {
	//	case "JPG", "JPEG", "PNG":
	//
	//	}
	//}
}
