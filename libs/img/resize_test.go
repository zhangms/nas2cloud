package img

import (
	"io/fs"
	"io/ioutil"
	"testing"
)

func TestResize(t *testing.T) {
	dat, _ := ioutil.ReadFile("/Users/ZMS/Pictures/pigu.jpg")
	ret, _ := Resize(dat, 100, 100)
	_ = ioutil.WriteFile("test.jpg", ret, fs.ModePerm)
}
