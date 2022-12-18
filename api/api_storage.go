package api

import (
	"github.com/gofiber/fiber/v2"
)

type Resp struct {
	Count int64
	Size  int64
}

func fileList(c *fiber.Ctx) error {
	//return c.JSON(storage.Ext())
	return c.SendString("hello world")
}
