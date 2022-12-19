package api

import (
	"github.com/gofiber/fiber/v2"
	"nas2cloud/svc/storage"
)

type Resp struct {
	Count int64
	Size  int64
}

func fileList(c *fiber.Ctx) error {
	return c.JSON(ResultOK(storage.List("zms", "/")))
}
