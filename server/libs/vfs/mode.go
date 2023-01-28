package vfs

import "strings"

func IsModeWriteable(mode string) bool {
	return strings.Contains(mode, "w")
}

func IsModeReadable(mode string) bool {
	return strings.Contains(mode, "r")
}

func IsModeReadWrite(mode string) bool {
	return strings.Contains(mode, "rw")
}
