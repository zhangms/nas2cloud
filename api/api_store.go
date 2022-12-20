package api

import (
	"github.com/gofiber/fiber/v2"
	"nas2cloud/svc/storage"
)

func storeList(c *fiber.Ctx) error {
	p := c.Params("*", "/")
	list := storage.List("zms", p)
	return c.JSON(ResultOK(list))
}
