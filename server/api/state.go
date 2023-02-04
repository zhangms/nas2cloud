package api

import (
	"encoding/json"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc/sign"
	"net/http"
	"strings"

	"github.com/gofiber/fiber/v2"
)

type StateController struct {
}

var stateController = &StateController{}

func (*StateController) State(c *fiber.Ctx) error {
	type Response struct {
		AppName       string `json:"appName,omitempty"`
		StaticAddress string `json:"staticAddress,omitempty"`
		UserAvatar    string `json:"userAvatar,omitempty"`
		UserName      string `json:"userName,omitempty"`
		PublicKey     string `json:"publicKey,omitempty"`
	}
	resp := &Response{
		AppName:       "平淼淼和大树的Family",
		StaticAddress: "",
	}
	key, err := sign.Sign().GetPublicKey("sys")
	if err != nil {
		return SendError(c, http.StatusInternalServerError, "SERVER_STATUS_ERROR")
	}
	resp.PublicKey = key
	u, _ := GetContextUser(c)
	if u != nil {
		resp.UserName = u.Name
		resp.UserAvatar = u.Avatar
	}
	return SendOK(c, resp)
}

func (*StateController) CheckUpdates(c *fiber.Ctx) error {
	var bucket = "/Releases"
	data, err := vfs.Read("root", bucket+"/release.json")
	if err != nil {
		return SendMsg(c, "no_updates")
	}
	mp := make(map[string]string)
	json.Unmarshal(data, &mp)
	device := strings.Split(c.Get(keyDevice), ",")
	release, ok := mp[device[0]]
	if !ok {
		return SendMsg(c, "no_updates")
	}
	return SendMsg(c, bucket+"/"+release)
}
