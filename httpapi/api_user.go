package httpapi

import (
	"encoding/json"
	"github.com/gofiber/fiber/v2"
	"nas2cloud/libs/logger"
	"nas2cloud/services/user"
	"net/http"
)

func userLogin(c *fiber.Ctx) error {
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
		return SendError(c, http.StatusBadRequest, "request error")
	}
	token, err := user.Login(request.UserName, request.Password)
	if err != nil {
		return SendError(c, http.StatusForbidden, err.Error())
	}
	return SendOK(c, &loginResponse{
		UserName: request.UserName,
		Token:    token,
	})
}
