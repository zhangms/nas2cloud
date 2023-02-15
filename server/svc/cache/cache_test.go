package cache

import (
	"fmt"
	"testing"
)

func TestName(t *testing.T) {

	DoInit("dev")

	key := "{Docs}:v1_file_/Docs/Screen Shot 2023-01-25 at 01.32.17.png"

	//ret, err := Set(key, "hello world")
	//println(ret, err)

	count, er2 := Exists(key)
	fmt.Println(count, er2)

}
