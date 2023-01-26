package api

import (
	"nas2cloud/svc/sign"
	"net/http"

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

	key, err := sign.Sign().GetPublicKey()
	if err != nil {
		return SendError(c, http.StatusInternalServerError, err.Error())
	}

	u, _ := GetContextUser(c)
	if u != nil {
		resp.UserName = u.Name
		resp.UserAvatar = u.Avatar
	}

	resp.PublicKey = key
	return SendOK(c, resp)
}
