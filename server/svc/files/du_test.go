package files

import (
	"fmt"
	"nas2cloud/libs"
	"strconv"
	"strings"
	"testing"
)

func TestDu(t *testing.T) {
	str := `
	DU v1.62 - Directory disk usage reporter
	Copyright (C) 2005-2018 Mark Russinovich
	Sysinternals - www.sysinternals.com
	
	Files:        24302
	Directories:  209
	Size:         182,729,128,289 bytes
	Size on disk: 184,343,986,176 bytes
	`

	arr := strings.Split(strings.TrimSpace(str), "\n")
	size := strings.TrimSpace(arr[len(arr)-1])
	size = strings.TrimSpace(strings.Split(size, ":")[1])
	size = strings.TrimSpace(strings.Split(size, " ")[0])
	size = strings.ReplaceAll(size, ",", "")
	sizei, _ := strconv.Atoi(size)
	fmt.Println(libs.ReadableDataSize(int64(sizei)))

}
