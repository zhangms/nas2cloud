package main

import (
	"github.com/gofiber/fiber/v2"
	"nas2cloud/api"
	"nas2cloud/libs/logger"
	_ "nas2cloud/libs/vfs"
	_ "nas2cloud/svc/dao"
)

func main() {
	app := fiber.New()
	api.Register(app)
	err := app.Listen(":8080")
	if err != nil {
		logger.Error(err)
	}
}
