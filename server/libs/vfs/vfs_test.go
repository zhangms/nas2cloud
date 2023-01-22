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

func TestState(t *testing.T) {
	file, err := os.Stat("/Users/ZMS/Thumb/favorite.jpg")
	if err != nil {
		t.Error(err)
	} else {
		fmt.Println(file)
	}

	// info, err := Info("family", "/thumb/favorite.jpg")
	// fmt.Println(info, err)

}
