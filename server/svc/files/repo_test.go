package files

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc/es"
	"testing"
	"time"
)

func TestDeleteIndex(t *testing.T) {
	initRepository("docker")
	err := es.DeleteIndex("docker_files")
	if err != nil {
		t.Error(err)
	}
}

func TestSave(t *testing.T) {
	initRepository("docker")
	for i := 500; i < 20000; i++ {
		dur := int64(int64(time.Hour) * int64(i))
		info := &vfs.ObjectInfo{
			Path:    fmt.Sprintf("/Pic/mock/aaaa_%d.png", i),
			Name:    fmt.Sprintf("aaaa_%d.png", i),
			Ext:     ".PNG",
			Preview: "/thumb/aaa.png",
			Size:    1023,
			Hidden:  false,
			Type:    vfs.ObjectTypeFile,
			CreTime: time.Now().Add(time.Duration(dur)).UnixMilli(),
			ModTime: time.Now().Add(time.Duration(dur)).UnixMilli(),
		}
		err := repo.save(info)
		if err != nil {
			t.Error(err)
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

func TestSearchPhoto(t *testing.T) {
	initRepository("dev")
	ret, after, err := repo.searchPhotos([]string{"Movies", "Pic"}, "2022-01", "")
	if err != nil {
		t.Error(err)
	}
	data, _ := json.Marshal(ret)
	fmt.Println(string(data))
	fmt.Println(after)
}

func TestSearchPhotosMonthAggs(t *testing.T) {
	initRepository("dev")
	kv, err := repo.searchPhotosGroupTimeCount([]string{"Movies", "Pic"})
	var count int64 = 0
	for _, k := range kv {
		count += k.Value
	}
	fmt.Println(count)
	data, _ := json.Marshal(kv)
	fmt.Println(string(data))
	fmt.Println(err)
}
