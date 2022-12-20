package external

import (
	"encoding/json"
	"fmt"
	"testing"
)

func TestExternal(t *testing.T) {

	ret, _ := Storage.List("external:/Documents/")
	for _, r := range ret {
		d, _ := json.Marshal(r)
		fmt.Println(string(d))
	}

	fmt.Println("---------------")

	i, _ := Storage.Info("external:/Documents")
	d1, _ := json.Marshal(i)
	fmt.Println(string(d1))

}
