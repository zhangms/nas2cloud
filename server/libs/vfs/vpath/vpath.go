package vpath

import (
	"regexp"
	"strings"
)

const separator = "/"

func Clean(path string) string {
	p := separator + path
	p = strings.ReplaceAll(p, "\\", separator)
	reg, _ := regexp.Compile("/+")
	return reg.ReplaceAllString(p, separator)
}

func Base(path string) string {
	p := Clean(path)
	arr := strings.Split(p, separator)
	return arr[len(arr)-1]
}

func Dir(path string) string {
	p := Clean(path)
	arr := strings.Split(p, separator)
	parent := arr[0 : len(arr)-1]
	return Clean(strings.Join(parent, separator))
}

func Ext(path string) string {
	p := Clean(path)
	index := strings.LastIndex(p, ".")
	if index > 0 {
		return strings.ToUpper(path[index:])
	}
	return ""
}

func Join(path ...string) string {
	return Clean(strings.Join(path, separator))
}

func IsRootDir(p string) bool {
	return Clean(p) == separator
}

func GetBucketFile(file string) (string, string) {
	pth := Clean(file)
	arr := strings.SplitN(pth, string(separator), 3)
	if len(arr) == 3 {
		return arr[1], arr[2]
	}
	return arr[1], ""
}

func Split(path string) (dir, file string) {
	p := Clean(file)
	arr := strings.Split(p, separator)
	parent := arr[0 : len(arr)-1]
	base := arr[len(arr)-1]
	return Clean(strings.Join(parent, separator)), base
}
