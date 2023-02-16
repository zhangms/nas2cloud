package api

import (
	"encoding/json"
	"fmt"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs/vpath"
	"nas2cloud/svc/files"
	"net/http"
	"net/url"
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
	u, _ := GetContextUser(c)
	if !u.WriteMode() {
		return SendError(c, http.StatusBadRequest, "no auth")
	}
	folderName := strings.TrimSpace(req.FolderName)
	if len(folderName) == 0 {
		return SendError(c, http.StatusBadRequest, "name cant empty")
	}
	fullPath := vpath.Join(req.Path, folderName)
	err = files.MkdirAll(u.Name, fullPath)
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
	u, _ := GetContextUser(c)
	if !u.WriteMode() {
		return SendError(c, http.StatusBadRequest, "no auth")
	}
	err = files.Remove(u.Name, req.Path)
	if err != nil {
		logger.ErrorStacktrace(err, req.Path)
		return SendError(c, http.StatusForbidden, "file can't delete")
	}
	return SendOK(c, "OK")
}

func (f *FileController) Exists(c *fiber.Ctx) error {
	path, _ := url.PathUnescape(c.Params("*"))
	u, _ := GetContextUser(c)
	exists, err := files.Exists(u.Name, path)
	if err != nil {
		return SendError(c, http.StatusForbidden, err.Error())
	}
	return SendMsg(c, fmt.Sprintf("%v", exists))
}

func (f *FileController) ListExists(c *fiber.Ctx) error {
	type request struct {
		Path []string `json:"paths"`
	}
	req := &request{}
	err := json.Unmarshal(c.Body(), req)
	if err != nil {
		return SendError(c, http.StatusBadRequest, err.Error())
	}
	u, _ := GetContextUser(c)
	ret := make([]int, 0, len(req.Path))
	for _, v := range req.Path {
		exists, err := files.Exists(u.Name, v)
		if err != nil {
			return SendError(c, http.StatusForbidden, err.Error())
		}
		if exists {
			ret = append(ret, 1)
		} else {
			ret = append(ret, 0)
		}
	}
	return SendOK(c, ret)
}

func (f *FileController) Upload(c *fiber.Ctx) error {
	path, _ := url.PathUnescape(c.Params("*"))
	file, err := c.FormFile("file")
	if err != nil {
		return SendError(c, http.StatusBadRequest, err.Error())
	}
	u, _ := GetContextUser(c)
	if !u.WriteMode() {
		return SendError(c, http.StatusBadRequest, "no auth")
	}
	fullPath := vpath.Join(path, file.Filename)
	exists, err := files.Exists(u.Name, fullPath)
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
	info, err := files.Upload(u.Name, fullPath, stream, time.UnixMilli(lastModified))
	if err != nil {
		return SendError(c, http.StatusBadRequest, err.Error())
	}
	return SendOK(c, info)
}

func (f *FileController) ToggleFavorite(c *fiber.Ctx) error {
	type request struct {
		Name string `json:"name"`
		Path string `json:"path"`
	}
	req := &request{}
	err := json.Unmarshal(c.Body(), req)
	if err != nil {
		return SendError(c, http.StatusBadRequest, err.Error())
	}
	u, _ := GetContextUser(c)
	favor, err := files.ToggleFavorite(u.Name, req.Name, req.Path)
	if err != nil {
		logger.ErrorStacktrace(err)
		return SendError(c, http.StatusInternalServerError, "ERROR")
	}
	return SendOK(c, fmt.Sprintf("%v", favor))
}
