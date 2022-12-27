package store

import (
	"errors"
	"github.com/gofiber/fiber/v2"
	"nas2cloud/api/base"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc/storage"
	"net/http"
	"net/url"
)

func Navigate(c *fiber.Ctx) error {
	u, _ := base.GetLoggedUser(c)
	body := make(map[string]string)
	_ = c.BodyParser(body)
	p := body["path"]
	list := storage.List(u.Name, p)
	return base.SendOK(c, list)
}

func NavigatePage(c *fiber.Ctx) error {
	fullPath, _ := url.QueryUnescape(c.Query("path", "/"))
	username := "zms"
	info, err := storage.Info(username, fullPath)
	if err != nil {
		return base.SendErrorPage(c, http.StatusBadRequest, err)
	}
	if info.Type != vfs.ObjectTypeDir {
		return base.SendErrorPage(c, http.StatusForbidden, errors.New("not support"))
	}
	list := storage.List(username, fullPath)
	data, err := createNavPage(fullPath, list)
	if err != nil {
		return base.SendErrorPage(c, http.StatusInternalServerError, err)
	}
	return base.SendPage(c, data)
}
