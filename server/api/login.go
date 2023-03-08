package api

import (
	"encoding/json"
	"fmt"
	"nas2cloud/libs/logger"
	"nas2cloud/svc/user"
	"net/http"
	"time"

	"github.com/gofiber/fiber/v2"
)

type LoginController struct {
}

var loginController = &LoginController{}

func (l *LoginController) Login(c *fiber.Ctx) error {
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
	fmt.Println(string(body))
	origin, err := decryptSign(string(body))
	if err != nil {
		logger.ErrorStacktrace(err, string(body))
		return SendError(c, http.StatusBadRequest, "request error")
	}
	if err = json.Unmarshal([]byte(origin), request); err != nil {
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
