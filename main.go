package main

import (
	"github.com/gofiber/fiber/v2"
	"nas2cloud/httpapi"
	"nas2cloud/libs/logger"
)

func main() {
	app := fiber.New()
	httpapi.Register(app)
	err := app.Listen(":8080")
	if err != nil {
		logger.Error(err)
	}
}
