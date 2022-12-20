package api

import (
	"github.com/gofiber/fiber/v2"
	"nas2cloud/res"
	"nas2cloud/svc/storage"
	"net/http"
)

func storePage(c *fiber.Ctx) error {
	p := c.Params("*", "/")
	list := storage.List("zms", p)
	data, err := res.ParseHtml("store.html", list)
	if err != nil {
		return SendErrorPage(c, http.StatusInternalServerError, err)
	}
	return SendPage(c, data)
}
