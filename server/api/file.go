package api

import (
	"encoding/json"
	"github.com/gofiber/fiber/v2"
	"nas2cloud/svc/storage"
	"net/http"
	"path/filepath"
	"strings"
)

type fileController struct {
}

var fileCtl = &fileController{}

func (f *fileController) CreateFolder(c *fiber.Ctx) error {
	type request struct {
		Path       string `json:"path"`
		FolderName string `json:"folderName"`
	}
	req := &request{}
	err := json.Unmarshal(c.Body(), req)
	if err != nil {
		return SendError(c, http.StatusBadRequest, err.Error())
	}
	u, _ := GetLoggedUser(c)
	folderName := strings.TrimSpace(req.FolderName)
	if len(folderName) == 0 {
		return SendError(c, http.StatusBadRequest, "name cant empty")
	}
	fullPath := filepath.Join(req.Path, folderName)
	err = storage.File().MkdirAll(u.Name, fullPath)
	if err != nil {
		return SendError(c, http.StatusBadRequest, err.Error())
	}
	return SendOK(c, "OK")
}

func (f *fileController) DeleteFile(c *fiber.Ctx) error {
	type request struct {
		Path string `json:"path"`
	}
	req := &request{}
	err := json.Unmarshal(c.Body(), req)
	if err != nil {
		return SendError(c, http.StatusBadRequest, err.Error())
	}
	u, _ := GetLoggedUser(c)
	err = storage.File().RemoveAll(u.Name, req.Path)
	if err != nil {
		return SendError(c, http.StatusBadRequest, err.Error())
	}
	return SendOK(c, "OK")
}
