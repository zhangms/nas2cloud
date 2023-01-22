package api

import (
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
	}
	resp := &Response{
		AppName:       "平淼淼和大树的Family",
		StaticAddress: "",
	}
	u, _ := GetLoggedUser(c)
	if u != nil {
		resp.UserName = u.Name
		resp.UserAvatar = u.Avatar
	}
	SendOK(c, resp)
	return nil
}
