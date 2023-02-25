package api

import (
	"encoding/json"
	"errors"
	"math"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/libs/vfs/vpath"
	"nas2cloud/svc/files"
	"nas2cloud/svc/user"
	"net/http"
	"time"

	"github.com/gofiber/fiber/v2"
)

type fileWalkRequest struct {
	Path     string `json:"path,omitempty"`
	PageNo   int    `json:"pageNo,omitempty"`
	PageSize int    `json:"pageSize,omitempty"`
	OrderBy  string `json:"orderBy,omitempty"`
}

type fileWalkResult struct {
	Nav          []*fileWalkNav `json:"nav"`
	Files        []*fileItem    `json:"files"`
	Total        int64          `json:"total"`
	CurrentPath  string         `json:"currentPath"`
	CurrentStart int64          `json:"currentStart"`
	CurrentStop  int64          `json:"currentStop"`
	CurrentPage  int            `json:"currentPage"`
}

type fileWalkNav struct {
	Path string `json:"path"`
	Name string `json:"name"`
}

type fileItem struct {
	Name      string `json:"name"`
	Path      string `json:"path"`
	Thumbnail string `json:"thumbnail"`
	Type      string `json:"type"`
	Size      string `json:"size"`
	ModTime   string `json:"modTime"`
	Ext       string `json:"ext"`
	Favor     bool   `json:"favor"`
	FavorName string `json:"favorName"`
}

func (f *FileController) Walk(c *fiber.Ctx) error {
	u, _ := GetContextUser(c)
	request := f.walkRequest(c)
	resp, err := f.walk(u, request)
	if err == nil {
		return SendOK(c, resp)
	}
	if errors.Is(err, files.RetryLaterAgain) {
		return SendError(c, http.StatusCreated, err.Error())
	}
	logger.ErrorStacktrace(err)
	return SendError(c, http.StatusInternalServerError, "ERROR")
}

func (f *FileController) walkRequest(c *fiber.Ctx) *fileWalkRequest {
	req := &fileWalkRequest{}
	_ = json.Unmarshal(c.Body(), req)
	if len(req.OrderBy) == 0 {
		req.OrderBy = "fileName"
	}
	return req
}

func (f *FileController) walk(u *user.User, request *fileWalkRequest) (*fileWalkResult, error) {
	pageSize := int(math.Min(100, float64(libs.If(request.PageSize <= 0, 50, request.PageSize).(int))))
	start := int64(request.PageNo * pageSize)
	stop := int64((request.PageNo + 1) * pageSize)
	lst, total, err := files.Walk(u.Name, request.Path, request.OrderBy, start, stop)
	if err != nil {
		return nil, err
	}
	favors, err := files.GetFavorsMap(u.Name)
	if err != nil {
		return nil, err
	}
	return &fileWalkResult{
		Nav:          f.parseToNav(u, request.Path),
		Files:        f.parseToFiles(lst, favors),
		Total:        total,
		CurrentPage:  request.PageNo,
		CurrentPath:  request.Path,
		CurrentStart: start,
		CurrentStop:  stop,
	}, nil
}

func (f *FileController) parseToFiles(lst []*vfs.ObjectInfo, favors map[string]string) []*fileItem {
	items := make([]*fileItem, 0)
	for _, itm := range lst {
		favorName, favor := favors[itm.Path]
		items = append(items, &fileItem{
			Name:      itm.Name,
			Path:      itm.Path,
			Thumbnail: itm.Preview,
			Type:      string(itm.Type),
			Size:      libs.ReadableDataSize(itm.Size),
			ModTime: libs.IF(itm.ModTime <= 0, func() any {
				return ""
			}, func() any {
				return time.UnixMilli(itm.ModTime).Format("2006-01-02 15:04")
			}).(string),
			Ext:       itm.Ext,
			Favor:     favor,
			FavorName: favorName,
		})
	}
	return items
}

func (f *FileController) parseToNav(u *user.User, pathName string) []*fileWalkNav {
	ret := make([]*fileWalkNav, 0)
	dir := vpath.Dir(pathName)
	name := vpath.Base(pathName)
	if len(name) == 0 {
		return ret
	}
	ret = append(ret, &fileWalkNav{
		Name: name,
		Path: "",
	})
	for {
		name = vpath.Base(dir)
		if len(name) == 0 {
			break
		}
		tmp := append([]*fileWalkNav{}, &fileWalkNav{
			Name: name,
			Path: dir,
		})
		tmp = append(tmp, ret...)
		ret = tmp
		dir = vpath.Dir(dir)
	}
	base := ret[0]
	baseInfo, _ := vfs.Info(u.Roles, base.Path)
	if baseInfo != nil {
		base.Name = baseInfo.Name
	}
	return ret
}

type photoResponse struct {
	SearchAfter string      `json:"searchAfter"`
	Files       []*fileItem `json:"files"`
}

func (f *FileController) SearchPhotos(c *fiber.Ctx) error {
	type request struct {
		SearchAfter string `json:"searchAfter"`
	}
	req := &request{}
	_ = json.Unmarshal(c.Body(), req)

	u, _ := GetContextUser(c)
	items, after, err := files.Photos(u.Name, req.SearchAfter)
	if err != nil {
		return SendError(c, http.StatusInternalServerError, err.Error())
	}
	fileItems := f.parseToFiles(items, map[string]string{})
	resp := &photoResponse{
		SearchAfter: after,
		Files:       fileItems,
	}
	return SendOK(c, resp)
}
