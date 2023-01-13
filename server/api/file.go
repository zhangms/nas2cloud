package api

import (
	"encoding/json"
	"fmt"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/svc/storage"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
)

type FileController struct {
}

var fileController = &FileController{}

func (f *FileController) CreateFolder(c *fiber.Ctx) error {
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

func (f *FileController) DeleteFiles(c *fiber.Ctx) error {
	type request struct {
		Path []string `json:"paths"`
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

func (f *FileController) Upload(c *fiber.Ctx) error {
	path := "/" + c.Params("*")
	file, err := c.FormFile("file")
	if err != nil {
		return SendError(c, http.StatusBadRequest, err.Error())
	}
	u, _ := GetLoggedUser(c)
	fullPath := filepath.Join(path, file.Filename)
	exists, err := storage.File().Exists(u.Name, fullPath)
	if err != nil {
		return SendError(c, http.StatusBadRequest, err.Error())
	}
	if exists {
		return SendError(c, http.StatusBadRequest, "FileExistsAlready")
	}
	logger.Info("upload:", path, file.Filename, libs.ReadableDataSize(file.Size), file.Header)
	stream, err := file.Open()
	if err != nil {
		return SendError(c, http.StatusBadRequest, err.Error())
	}

	lastModified, err := strconv.ParseInt(c.FormValue("lastModified",
		fmt.Sprintf("%d", time.Now().UnixMilli())), 10, 64)
	if err != nil {
		lastModified = time.Now().UnixMilli()
	}
	err = storage.File().Upload(u.Name, fullPath, stream, time.UnixMilli(lastModified))
	if err != nil {
		return SendError(c, http.StatusBadRequest, err.Error())
	}
	return SendOK(c, "OK")
}
