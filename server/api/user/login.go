package user

import (
	"encoding/json"
	"github.com/gofiber/fiber/v2"
	"nas2cloud/api/base"
	"nas2cloud/libs/logger"
	"nas2cloud/svc/user"
	"net/http"
)

func Login(c *fiber.Ctx) error {
	type loginRequest struct {
		UserName string `json:"username"`
		Password string `json:"password"`
	}
	type loginResponse struct {
		UserName string `json:"username"`
		Token    string `json:"token"`
	}
	request := &loginRequest{}
	body := c.Body()
	err := json.Unmarshal(body, request)
	if err != nil {
		logger.ErrorStacktrace(err, string(body))
		return base.SendError(c, http.StatusBadRequest, "request error")
	}
	token, err := user.Login(request.UserName, request.Password, c.Get("device"))
	if err != nil {
		return base.SendError(c, http.StatusForbidden, err.Error())
	}
	return base.SendOK(c, &loginResponse{
		UserName: request.UserName,
		Token:    token,
	})
}
