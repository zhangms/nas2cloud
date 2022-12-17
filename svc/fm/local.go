package fm

import (
	"fmt"
	"io/ioutil"
	"nas2cloud/libs/logger"
	"os"
)

func Walk(path string) (int64, int64) {
	fi, err := os.Stat(path)
	if err != nil {
		logger.Error(err)
		return 0, 0
	}
	if !fi.IsDir() {
		return 1, fi.Size()
	}
	fs, err := ioutil.ReadDir(path)
	if err != nil {
		fmt.Println(err)
		return 0, 0
	}
	var count int64 = 0
	var size int64 = 0
	for _, file := range fs {
		count++
		size += file.Size()
		if file.IsDir() {
			c1, s1 := Walk(path + "/" + file.Name())
			count += c1
			size += s1
		}
	}
	fmt.Printf("%s, fileCount:%d, size:%d\n", path, count, size*1.0/1024/1024)
	return count, size
}
