package store

import (
	"encoding/json"
	"fmt"
	"testing"
)

func TestName(t *testing.T) {

	u := list("zms", "/Documents/ProjectBase/2020/aa.txt")
	data, _ := json.Marshal(u)
	fmt.Println(string(data))

}
