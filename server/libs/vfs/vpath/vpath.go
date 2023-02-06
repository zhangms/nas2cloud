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
	p = reg.ReplaceAllString(p, separator)
	if len(p) > 1 && p[len(p)-1:] == separator {
		return p[0 : len(p)-1]
	}
	return p
}

func Base(path string) string {
	p := Clean(path)
	arr := strings.Split(p, separator)
	base := arr[len(arr)-1]
	if len(base) > 1 && base[len(base)-1:] == separator {
		return base[0 : len(base)-1]
	}
	return base
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

func BucketFile(file string) (string, string) {
	pth := Clean(file)
	arr := strings.SplitN(pth, string(separator), 3)
	if len(arr) == 3 {
		return arr[1], arr[2]
	}
	return arr[1], ""
}

func Split(path string) (dir, file string) {
	return Dir(path), Base(path)
}
