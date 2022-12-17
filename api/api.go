package api

import (
	"github.com/gofiber/fiber/v2"
	"net/http"
)

func Register(app *fiber.App) {
	app.Get("/file/list", fileList)
	app.Post("/user/login", userLogin)
}

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
