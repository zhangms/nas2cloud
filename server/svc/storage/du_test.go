package storage

import (
	"fmt"
	"testing"
)

func TestDu(t *testing.T) {
	u, err := disk.duAllParent("/Pic/test2")
	if err != nil {
		t.Error(err)
	}
	for _, d := range u {
		fmt.Println(d)
	}
}
