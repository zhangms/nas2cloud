package local

import (
	"fmt"
	"testing"
)

func TestLocalStore(t *testing.T) {

	objs := Store.List("/Users/ZMS/Documents")
	for _, o := range objs {
		fmt.Printf("%#v\n", o)
	}

}
