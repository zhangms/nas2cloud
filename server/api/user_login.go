package api

import (
	"encoding/json"
	"github.com/gofiber/fiber/v2"
	"nas2cloud/libs/logger"
	"nas2cloud/svc/user"
	"net/http"
	"time"
)

type login struct {
}

var loginCtrl = &login{}

func (l *login) Login(c *fiber.Ctx) error {
	type loginRequest struct {
		UserName string `json:"username"`
		Password string `json:"password"`
	}
	type loginResponse struct {
		UserName   string `json:"username"`
		Token      string `json:"token"`
		CreateTime string `json:"createTime"`
	}

	request := &loginRequest{}
	body := c.Body()
	err := json.Unmarshal(body, request)
	if err != nil {
		logger.ErrorStacktrace(err, string(body))
		return SendError(c, http.StatusBadRequest, "request error")
	}
	token, err := user.Login(request.UserName, request.Password, c.Get("X-DEVICE"))
	if err != nil {
		c.ClearCookie("authToken")
		return SendError(c, http.StatusForbidden, err.Error())
	}
	return SendOK(c, &loginResponse{
		UserName:   request.UserName,
		Token:      token,
		CreateTime: time.Now().Format(time.RFC3339),
	})
}
