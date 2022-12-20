package local

import (
	"fmt"
	"testing"
)

func TestLocalStore(t *testing.T) {

	objs, _ := Storage.List("/Users/ZMS/Documents")
	for _, o := range objs {
		fmt.Printf("%#v\n", o)
	}

}
