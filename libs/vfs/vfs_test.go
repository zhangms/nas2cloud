package vfs

import (
	"encoding/json"
	"fmt"
	"testing"
)

func TestName(t *testing.T) {

	info, err := Info("family", "/Docs")
	if err != nil {
		t.Error(err)
	}
	data, _ := json.Marshal(info)
	fmt.Println(string(data))

}
