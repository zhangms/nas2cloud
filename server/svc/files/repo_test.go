package files

import (
	"nas2cloud/libs/vfs"
	"testing"
	"time"
)

func TestSave(t *testing.T) {

	initRepository("dev")

	now := time.Now()
	repo.save(&vfs.ObjectInfo{
		Name:    "abc.png",
		Path:    "/path/to/abc.png",
		Type:    vfs.ObjectTypeDir,
		Hidden:  false,
		CreTime: now.UnixMilli(),
		ModTime: now.UnixMilli(),
		Preview: "",
		Size:    1234567890,
		Ext:     ".PNG",
	})

}
