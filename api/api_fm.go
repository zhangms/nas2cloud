package api

import (
	"github.com/gofiber/fiber/v2"
	"nas2cloud/svc/fm"
)

type Resp struct {
	Count int64
	Size  int64
}

func fileList(c *fiber.Ctx) error {
	count, size := fm.Walk(c.Query("path"))
	resp := &Resp{
		Count: count,
		Size:  size,
	}
	return c.JSON(resp)
}
