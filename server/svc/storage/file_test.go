package storage

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"path/filepath"
	"strconv"
	"testing"
	"time"
)

func TestWalk(t *testing.T) {
	var size int64
	err := filepath.Walk("/Users/ZMS/Pictures/test", func(path string, info fs.FileInfo, err error) error {
		size += info.Size()
		fmt.Println(info.Name())
		return nil
	})
	fmt.Println(err)
	fmt.Println(libs.ReadableDataSize(size))
}

func TestName(t *testing.T) {
	str := "[{\"Name\":\"Movies\",\"Path\":\"/Movies\",\"Type\":\"DIR\",\"Hidden\":false,\"CreTime\":null,\"ModTime\":\"2022-06-13T23:25:37.982544569+08:00\",\"MD5Sum\":\"\",\"Preview\":\"\",\"Size\":224,\"Ext\":\"\"},{\"Name\":\"Pic\",\"Path\":\"/Pic\",\"Type\":\"DIR\",\"Hidden\":false,\"CreTime\":null,\"ModTime\":\"2022-12-24T22:18:45.293498133+08:00\",\"MD5Sum\":\"\",\"Preview\":\"\",\"Size\":736,\"Ext\":\"\"},{\"Name\":\"Downloads\",\"Path\":\"/Downloads\",\"Type\":\"DIR\",\"Hidden\":false,\"CreTime\":null,\"ModTime\":\"2022-12-27T23:58:07.561576294+08:00\",\"MD5Sum\":\"\",\"Preview\":\"\",\"Size\":832,\"Ext\":\"\"},{\"Name\":\"Docs\",\"Path\":\"/Docs\",\"Type\":\"DIR\",\"Hidden\":false,\"CreTime\":null,\"ModTime\":\"2022-10-18T21:02:47.245442022+08:00\",\"MD5Sum\":\"\",\"Preview\":\"\",\"Size\":672,\"Ext\":\"\"}]"
	ret := make([]*vfs.ObjectInfo, 0)
	err := json.Unmarshal([]byte(str), &ret)
	fmt.Println(err)
}

func TestNumber(t *testing.T) {

	str := time.Now().Format("20060102150405")
	fmt.Println(str)
	v, e := strconv.Atoi(str)
	fmt.Println(v, e)

}

func TestList(t *testing.T) {
	lst, total, err := FileWalk().Walk("zms", "/Movies", "fileName", 0, 5)
	if err != nil {
		logger.ErrorStacktrace(err)
		return
	}
	fmt.Println(total)
	for _, item := range lst {
		data, _ := json.Marshal(item)
		fmt.Println(string(data))
	}
	for true {
		time.Sleep(time.Second)
	}

}
