package main

import (
	"fmt"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"nas2cloud/api"
	"nas2cloud/env"
	logger2 "nas2cloud/libs/logger"
	_ "nas2cloud/libs/vfs"
	_ "nas2cloud/svc/db"
)

func main() {
	app := fiber.New(fiber.Config{
		BodyLimit: 1024 * 1024 * 1024, //1G
	})
	app.Use(logger.New())
	api.Register(app)
	err := app.Listen(fmt.Sprintf(":%d", env.GetPort()))
	if err != nil {
		logger2.ErrorStacktrace(err)
	}
}
