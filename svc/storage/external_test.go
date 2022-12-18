package storage

import (
	"encoding/json"
	"fmt"
	"testing"
)

func TestExternal(t *testing.T) {

	ret := storeExternal.list("external://Downloads")
	for _, r := range ret {
		d, _ := json.Marshal(r)
		fmt.Println(string(d))
	}

	fmt.Println("---------------")

	i := storeExternal.info("external://Downloads")
	d1, _ := json.Marshal(i)
	fmt.Println(string(d1))

}
