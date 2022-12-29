package store

import (
	"encoding/json"
	"github.com/gofiber/fiber/v2"
	"nas2cloud/api/base"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
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

type listResult struct {
	Navigate []*navigate `json:"navigate"`
	Files    []*fileItem `json:"files"`
}

func List(c *fiber.Ctx) error {
	u, _ := base.GetLoggedUser(c)
	body := make(map[string]string)
	_ = json.Unmarshal(c.Body(), &body)
	p := body["path"]
	if len(p) == 0 {
		p = "/"
	}
	resp, err := list(u.Name, p)
	if err != nil {
		logger.ErrorStacktrace(err)
		return base.SendError(c, http.StatusInternalServerError, "ERROR")
	}
	return base.SendOK(c, resp)
}

func list(username string, p string) (*listResult, error) {
	lst, err := storage.List(username, p)
	if err != nil {
		return nil, err
	}
	return &listResult{
		Navigate: func() []*navigate {
			ret := make([]*navigate, 0)
			pp := filepath.Clean(p)
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
		}(),
		Files: func() []*fileItem {

			items := make([]*fileItem, 0)
			for _, item := range lst {
				items = append(items, &fileItem{
					Name:      item.Name,
					Path:      item.Path,
					Thumbnail: item.Preview,
					Type:      string(item.Type),
					Size:      libs.ReadableDataSize(item.Size),
					ModTime:   item.ModTime.Format("2006-01-02 15:04"),
					Ext:       item.Ext,
				})
			}
			return items
		}(),
	}, nil
}
