package files

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"nas2cloud/libs/vfs"
	"testing"
	"time"
)

func TestSave(t *testing.T) {
	initRepository("dev")

	for i := 0; i < 100; i++ {
		now := time.Now().AddDate(0, 0, i)
		err := repo.save(&vfs.ObjectInfo{
			Name:    fmt.Sprintf("abc%d.png", i),
			Path:    fmt.Sprintf("/path/to/abc%d.png", i),
			Type:    vfs.ObjectTypeDir,
			Hidden:  false,
			CreTime: now.UnixMilli(),
			ModTime: now.UnixMilli(),
			Preview: "",
			Size:    1234567890,
			Ext:     ".PNG",
		})
		fmt.Println(err)
	}
}

func TestSaveIfAbsent(t *testing.T) {
	initRepository("dev")
	now := time.Now()
	err := repo.saveIfAbsent(&vfs.ObjectInfo{
		Name:    "abc.png",
		Path:    "/path/to",
		Type:    vfs.ObjectTypeDir,
		Hidden:  false,
		CreTime: now.UnixMilli(),
		ModTime: now.UnixMilli(),
		Preview: "",
		Size:    1234567890,
		Ext:     ".PNG",
	})
	fmt.Println(err)
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
	path := "/path/to"
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
	ret, total, err := repo.walk("/path/to", "fileName_desc", 50, 100)
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
