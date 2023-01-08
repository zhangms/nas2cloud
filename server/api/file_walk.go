package api

import (
	"encoding/json"
	"github.com/gofiber/fiber/v2"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc"
	"nas2cloud/svc/storage"
	"net/http"
	"path/filepath"
)

type fileWalkRequest struct {
	Path    string `json:"path"`
	PageNo  int    `json:"pageNo"`
	OrderBy string `json:"orderBy"`
}

type fileWalkResult struct {
	Nav          []*fileWalkNav  `json:"nav"`
	Files        []*fileWalkItem `json:"files"`
	Total        int64           `json:"total"`
	CurrentPath  string          `json:"currentPath"`
	CurrentIndex int64           `json:"currentIndex"`
	CurrentPage  int             `json:"currentPage"`
}

type fileWalkNav struct {
	Path string `json:"path"`
	Name string `json:"name"`
}

type fileWalkItem struct {
	Name      string `json:"name"`
	Path      string `json:"path"`
	Thumbnail string `json:"thumbnail"`
	Type      string `json:"type"`
	Size      string `json:"size"`
	ModTime   string `json:"modTime"`
	Ext       string `json:"ext"`
}

func (f *fileController) Walk(c *fiber.Ctx) error {
	u, _ := GetLoggedUser(c)
	request := f.walkRequest(c)
	resp, err := f.walk(u.Name, request)
	if err == svc.RetryLaterAgain {
		return SendError(c, http.StatusCreated, err.Error())
	}
	if err != nil {
		logger.ErrorStacktrace(err)
		return SendError(c, http.StatusInternalServerError, "ERROR")
	}
	return SendOK(c, resp)
}

func (f *fileController) walkRequest(c *fiber.Ctx) *fileWalkRequest {
	req := &fileWalkRequest{}
	_ = json.Unmarshal(c.Body(), req)
	if len(req.OrderBy) == 0 {
		req.OrderBy = "fileName"
	}
	return req
}

func (f *fileController) walk(username string, request *fileWalkRequest) (*fileWalkResult, error) {
	pageSize := 100
	start := int64(request.PageNo * pageSize)
	stop := int64((request.PageNo+1)*pageSize - 1)
	lst, total, err := storage.File().Walk(username, request.Path, request.OrderBy, start, stop)
	if err != nil {
		return nil, err
	}
	return &fileWalkResult{
		Nav:          f.parseToNav(request.Path),
		Files:        f.parseToFiles(lst),
		Total:        total,
		CurrentPage:  request.PageNo,
		CurrentPath:  request.Path,
		CurrentIndex: stop,
	}, nil
}

func (f *fileController) parseToFiles(lst []*vfs.ObjectInfo) []*fileWalkItem {
	items := make([]*fileWalkItem, 0)
	for _, itm := range lst {
		items = append(items, &fileWalkItem{
			Name:      itm.Name,
			Path:      itm.Path,
			Thumbnail: itm.Preview,
			Type:      string(itm.Type),
			Size:      libs.ReadableDataSize(itm.Size),
			ModTime:   itm.ModTime.Format("2006-01-02 15:04"),
			Ext:       itm.Ext,
		})
	}
	return items
}

func (f *fileController) parseToNav(pathName string) []*fileWalkNav {
	ret := make([]*fileWalkNav, 0)
	pp := filepath.Clean(pathName)
	dir := filepath.Dir(pp)
	name := filepath.Base(pp)
	if name == "/" || name == "." {
		return ret
	}
	ret = append(ret, &fileWalkNav{
		Name: name,
		Path: "",
	})
	for {
		name = filepath.Base(dir)
		if name == "/" || name == "." {
			break
		}
		tmp := append([]*fileWalkNav{}, &fileWalkNav{
			Name: name,
			Path: dir,
		})
		tmp = append(tmp, ret...)
		ret = tmp
		dir = filepath.Dir(dir)
	}
	return ret
}