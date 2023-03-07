package vpath

import (
	"fmt"
	"path/filepath"
	"testing"
)

func TestClean(t *testing.T) {
	str := "C:\\hello\\world"

	fmt.Println(Clean(str))
}

func TestAbs(t *testing.T) {
	str := "client"
	fmt.Println(filepath.Abs(str))
}

func TestBase(t *testing.T) {
	str := "/"
	fmt.Println("----->", Base(str))
}

func TestDir(t *testing.T) {
	str := "/hello/world"
	fmt.Println("----->", Dir(str))
}

func TestExt(t *testing.T) {
	str := "world.png"
	fmt.Println("----->", Ext(str))
}
