package api

import (
	"fmt"
	"net/url"
	"testing"
)

func TestX(t *testing.T) {
	fmt.Println(url.QueryEscape("/app"))
}

func TestNav(t *testing.T) {
	// fmt.Println(url.QueryEscape("/app"))
	// var nav = fileController.parseToNav(u, "/user_zms_dir/xxx")
	// data, _ := json.Marshal(nav)
	// fmt.Println(string(data))
}

func TestDefer(t *testing.T) {
	v := testdefer()
	println(v)
}

func testdefer() (i int) {
	defer func() {
		i = 20
	}()
	i = 10
	return i
}
