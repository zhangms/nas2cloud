package api

import (
	"encoding/json"
	"fmt"
	"nas2cloud/svc/user"
	"net/url"
	"testing"
)

func TestX(t *testing.T) {
	fmt.Println(url.QueryEscape("/app"))
}

func TestNav(t *testing.T) {
	// fmt.Println(url.QueryEscape("/app"))
	u := user.GetUserByName("zms")
	var nav = fileController.parseToNav(u, "/user_zms_dir/xxx")
	data, _ := json.Marshal(nav)
	fmt.Println(string(data))
}
