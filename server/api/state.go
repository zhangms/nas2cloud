package api

import (
	"nas2cloud/libs"

	"github.com/gofiber/fiber/v2"
)

type StateController struct {
}

var stateController = &StateController{}

func (*StateController) State(c *fiber.Ctx) error {
	u, _ := GetLoggedUser(c)

	type Response struct {
		AppName  string `json:"appName,omitempty"`
		UserName string `json:"userName,omitempty"`
	}

	resp := &Response{
		AppName: "平淼淼和大树的Family",
		UserName: libs.IF(u != nil, func() any {
			return u.Name
		}, func() any {
			return ""
		}).(string),
	}
	SendOK(c, resp)
	return nil
}
