package storage

import (
	"fmt"
	"testing"
)

func TestLocalManager_List(t *testing.T) {

	localMgr := &LocalStore{}
	objs := localMgr.List("/Users/ZMS/Documents")
	for _, o := range objs {
		fmt.Printf("%#v\n", o)
	}

}
