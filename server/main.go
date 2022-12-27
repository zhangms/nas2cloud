package main

import (
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"nas2cloud/api"
	_ "nas2cloud/libs/vfs"
	_ "nas2cloud/svc/dao"
)

func main() {
	app := fiber.New()
	app.Use(logger.New())
	api.Register(app)
	err := app.Listen(":8080")
	if err != nil {
		//logger.ErrorStacktrace(err)
	}
}
