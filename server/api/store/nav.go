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
	//getStoreList(c)
	//return c.JSON(base.ResultOK(list))
	return nil
}

//func getStoreList(c *fiber.Ctx) {
//	p, _ := url.QueryUnescape(c.Query("path", "/"))
//	list := storage.List("zms", p)
//}

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
