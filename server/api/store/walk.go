package store

import (
	"encoding/json"
	"github.com/gofiber/fiber/v2"
	"nas2cloud/api/base"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc"
	"nas2cloud/svc/storage"
	"net/http"
	"path/filepath"
)

type navigate struct {
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
}

type walkResult struct {
	Navigate []*navigate `json:"navigate"`
	Files    []*fileItem `json:"files"`
	Total    int64
	Current  int64
	Page     int
}

type walkRequest struct {
	Path    string `json:"path"`
	PageNo  int    `json:"pageNo"`
	OrderBy string `json:"orderBy"`
}

func Walk(c *fiber.Ctx) error {
	u, _ := base.GetLoggedUser(c)
	request := getRequest(c)
	resp, err := walk(u.Name, request)
	if err == svc.RetryLaterAgain {
		return base.SendError(c, http.StatusCreated, err.Error())
	}
	if err != nil {
		logger.ErrorStacktrace(err)
		return base.SendError(c, http.StatusInternalServerError, "ERROR")
	}
	return base.SendOK(c, resp)
}

func getRequest(c *fiber.Ctx) *walkRequest {
	req := &walkRequest{}
	_ = json.Unmarshal(c.Body(), req)
	if len(req.OrderBy) == 0 {
		req.OrderBy = "fileName"
	}
	return req
}

func walk(username string, request *walkRequest) (*walkResult, error) {
	pageSize := 10
	start := int64(request.PageNo * pageSize)
	stop := int64((request.PageNo + 1) * pageSize)
	lst, total, err := storage.FileWalk().Walk(username, request.Path, request.OrderBy, start, stop)
	if err != nil {
		return nil, err
	}
	return &walkResult{
		Navigate: nav(request.Path),
		Files:    files(lst),
		Total:    total,
		Page:     request.PageNo,
		Current:  stop,
	}, nil
}

func files(lst []*vfs.ObjectInfo) []*fileItem {
	items := make([]*fileItem, 0)
	for _, itm := range lst {
		items = append(items, &fileItem{
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

func nav(pathName string) []*navigate {
	ret := make([]*navigate, 0)
	pp := filepath.Clean(pathName)
	dir := filepath.Dir(pp)
	name := filepath.Base(pp)
	if name == "/" || name == "." {
		return ret
	}
	ret = append(ret, &navigate{
		Name: name,
		Path: "",
	})
	for {
		name = filepath.Base(dir)
		if name == "/" || name == "." {
			break
		}
		tmp := append([]*navigate{}, &navigate{
			Name: name,
			Path: dir,
		})
		tmp = append(tmp, ret...)
		ret = tmp
		dir = filepath.Dir(dir)
	}
	return ret
}
