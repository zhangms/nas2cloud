package vfs

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"io/ioutil"
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
	err := ioutil.WriteFile("/Users/ZMS/Downloads/TESTXX/zz.txt", []byte("hello"), fs.ModePerm)
	fmt.Println(err)
}
