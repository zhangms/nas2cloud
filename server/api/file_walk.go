package api

import (
	"encoding/json"
	"math"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc"
	"nas2cloud/svc/storage"
	"net/http"
	"path/filepath"

	"github.com/gofiber/fiber/v2"
)

type fileWalkRequest struct {
	Path     string `json:"path,omitempty"`
	PageNo   int    `json:"pageNo,omitempty"`
	PageSize int    `json:"pageSize,omitempty"`
	OrderBy  string `json:"orderBy,omitempty"`
}

type fileWalkResult struct {
	Nav          []*fileWalkNav  `json:"nav"`
	Files        []*fileWalkItem `json:"files"`
	Total        int64           `json:"total"`
	CurrentPath  string          `json:"currentPath"`
	CurrentStart int64           `json:"currentStart"`
	CurrentStop  int64           `json:"currentStop"`
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

func (f *FileController) Walk(c *fiber.Ctx) error {
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

func (f *FileController) walkRequest(c *fiber.Ctx) *fileWalkRequest {
	req := &fileWalkRequest{}
	_ = json.Unmarshal(c.Body(), req)
	if len(req.OrderBy) == 0 {
		req.OrderBy = "fileName"
	}
	return req
}

func (f *FileController) walk(username string, request *fileWalkRequest) (*fileWalkResult, error) {
	pageSize := int(math.Min(math.Max(0, float64(request.PageSize)), 100))
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
		CurrentStart: start,
		CurrentStop:  stop,
	}, nil
}

func (f *FileController) parseToFiles(lst []*vfs.ObjectInfo) []*fileWalkItem {
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

func (f *FileController) parseToNav(pathName string) []*fileWalkNav {
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
