package base

import (
	"github.com/gofiber/fiber/v2"
	"nas2cloud/libs"
	"nas2cloud/res"
	"net/http"
)

type Result struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	Data    any    `json:"data"`
}

func ResultError(message string) *Result {
	return &Result{Success: false, Message: message}
}

func ResultOK(data any) *Result {
	return &Result{Success: true, Message: "OK", Data: data}
}

func SendError(c *fiber.Ctx, status int, message string) error {
	return c.Status(status).JSON(ResultError(message))
}

func SendOK(c *fiber.Ctx, data any) error {
	return c.Status(http.StatusOK).JSON(ResultOK(data))
}

func SendErrorPage(c *fiber.Ctx, status int, err error) error {
	c.Type("html", "utf-8")
	data, _ := res.ParseText("err.html", &struct {
		Message string
	}{
		Message: libs.IF(err != nil, func() any {
			return err.Error()
		}, func() any {
			return "some error"
		}).(string),
	})
	return c.Status(status).Send(data)
}

func SendPage(c *fiber.Ctx, data []byte) error {
	c.Type("html", "utf-8")
	return c.Send(data)
}
