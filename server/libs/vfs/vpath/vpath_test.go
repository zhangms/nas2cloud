package vpath

import (
	"fmt"
	"testing"
)

func TestClean(t *testing.T) {
	str := "C:\\hello\\world"

	fmt.Println(Clean(str))
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
	str := "/hello/world.png"
	fmt.Println("----->", Ext(str))
}
