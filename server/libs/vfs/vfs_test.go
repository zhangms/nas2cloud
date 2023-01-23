package vfs

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"os"
	"testing"
)

func TestName(t *testing.T) {

	info, err := Info("family", "/Docs")
	if err != nil {
		t.Error(err)
	}
	data, _ := json.Marshal(info)
	fmt.Println(string(data))

}

func TestWrite(t *testing.T) {
	err := os.WriteFile("/Users/ZMS/Downloads/TESTXX/zz.txt", []byte("hello"), fs.ModePerm)
	fmt.Println(err)
}

func TestList(t *testing.T) {
	infos, err := List("zms,family", "/")
	if err != nil {
		t.Error(err)
	} else {
		data, _ := json.Marshal(infos)
		fmt.Println(string(data))
	}
}
