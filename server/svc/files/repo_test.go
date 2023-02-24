package files

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc/es"
	"testing"
)

func TestDeleteIndex(t *testing.T) {
	initRepository("dev")
	err := es.DeleteIndex("dev_files")
	if err != nil {
		t.Error(err)
	}
}

func TestSave(t *testing.T) {
	initRepository("dev")
	vfs.Load("dev")

	items, err := vfs.List("root", "/Pic2/啊啊")
	if err != nil {
		t.Error(err)
	}
	for _, item := range items {
		if er := repo.saveIfAbsent(item); er != nil {
			t.Error(er)
		}
	}
}

func TestSaveIfAbsent(t *testing.T) {
	initRepository("dev")
	vfs.Load("dev")
	info, err := vfs.Info("root", "/Pic2/啊啊")
	if err != nil {
		t.Error(err)
	}
	err = repo.saveIfAbsent(info)
	if err != nil {
		t.Error(err)
	}
}

func TestGet(t *testing.T) {
	initRepository("dev")
	item, err := repo.get("/path/to/abc.png")
	data, _ := json.Marshal(item)
	fmt.Println(string(data), err)
}

func TestDelete(t *testing.T) {
	initRepository("dev")
	err := repo.delete("/path/to/abc.png")
	fmt.Println(err)
}

func TestBase64(t *testing.T) {
	str := "/path/to/aaa.jpg"
	ret := base64.RawURLEncoding.EncodeToString([]byte(str))
	fmt.Println(ret)
}

func TestUpdateSize(t *testing.T) {
	initRepository("dev")
	path := "/path/to/abc.png"
	err := repo.updateSize(path, 987)
	if err != nil {
		t.Error(err)
	}
	item, err := repo.get(path)
	data, _ := json.Marshal(item)
	fmt.Println(string(data), err)
}

func TestUpdatePreview(t *testing.T) {
	initRepository("dev")
	path := "/path/to/abc.png"
	err := repo.updatePreview(path, "/thumb/aaaa.jpg")
	if err != nil {
		t.Error(err)
	}
	item, err := repo.get(path)
	data, _ := json.Marshal(item)
	fmt.Println(string(data), err)
}

func TestUpdateModTime(t *testing.T) {
	initRepository("dev")
	path := "/Pic2"
	err := repo.updateDirModTimeByChildren(path)
	if err != nil {
		t.Error(err)
	}
	item, err := repo.get(path)
	data, _ := json.Marshal(item)
	fmt.Println(string(data), err)
}

func TestSearch(t *testing.T) {
	initRepository("dev")
	ret, total, err := repo.walk("/Pic", "fileName_desc", 0, 50)
	if err != nil {
		t.Error(err)
	}
	data, err := json.Marshal(ret)
	if err != nil {
		t.Error(err)
	}
	fmt.Println(total, string(data))
}

func TestJSON(t *testing.T) {

	type Person struct {
		Name   string `json:"name"`
		Age    int    `json:"properties.age"`
		Gender int    `json:"properties.gender"`
	}

	p := &Person{
		Name:   "zhangsan",
		Age:    20,
		Gender: 1,
	}

	data, _ := json.Marshal(p)
	fmt.Println(string(data))

}
