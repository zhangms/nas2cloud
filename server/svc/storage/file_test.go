package storage

import (
	"fmt"
	"io/fs"
	"nas2cloud/libs"
	"path/filepath"
	"testing"
)

func TestWalk(t *testing.T) {
	var size int64
	err := filepath.Walk("/Users/ZMS/Downloads", func(path string, info fs.FileInfo, err error) error {
		size += info.Size()
		return nil
	})
	fmt.Println(err)
	fmt.Println(libs.ReadableDataSize(size))
}
