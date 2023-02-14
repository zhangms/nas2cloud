package api

import (
	"encoding/json"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/res"
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
		AppName:       res.GetString("app.name"),
		StaticAddress: res.GetString("static.domain"),
	}
	key, err := sign.Instance().GetPublicKey("sys")
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
	var bucket = "/client"
	data, err := vfs.Read("root", bucket+"/release.json")
	if err != nil {
		return SendMsg(c, "no_updates")
	}
	mp := make(map[string]string)
	_ = json.Unmarshal(data, &mp)
	device := strings.Split(c.Get(keyDevice), ",")
	release, ok := mp[device[0]]
	if !ok {
		return SendMsg(c, "no_updates")
	}
	return SendMsg(c, bucket+"/"+release)
}

func (*StateController) TraceLog(c *fiber.Ctx) error {
	type request struct {
		Log string `json:"log"`
	}
	req := &request{}
	err := json.Unmarshal(c.Body(), req)
	if err != nil {
		return SendError(c, http.StatusBadRequest, err.Error())
	}
	logger.Info("client", req.Log)
	return SendOK(c, "OK")
}
