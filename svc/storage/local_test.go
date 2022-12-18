package storage

import (
	"fmt"
	"testing"
)

func TestLocalManager_List(t *testing.T) {

	localMgr := &localStore{}
	objs := localMgr.list("/Users/ZMS/Documents")
	for _, o := range objs {
		fmt.Printf("%#v\n", o)
	}

}
