package api

import (
	"github.com/gofiber/fiber/v2"
	"nas2cloud/libs/logger"
	"nas2cloud/res"
	"net/http"
)

func Register(app *fiber.App) {
	app.Get("/store/list/*", handler(storeList))
	app.Get("/store/page/*", handler(storePage))
	app.Post("/user/login", handler(userLogin))
}

func handler(impl func(c *fiber.Ctx) error) func(c *fiber.Ctx) error {
	return func(c *fiber.Ctx) error {
		defer func() {
			err := recover()
			if err != nil {
				logger.ErrorStacktrace(err, "api_handler_recovered")
				_ = SendError(c, http.StatusInternalServerError, "error")
			}
		}()
		return impl(c)
	}
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

func SendErrorPage(c *fiber.Ctx, status int, err error) error {
	c.Type("html", "utf-8")
	data, _ := res.ReadData("tpl/err.html")
	return c.Status(status).Send(data)
}

func SendPage(c *fiber.Ctx, data []byte) error {
	c.Type("html", "utf-8")
	return c.Send(data)
}
