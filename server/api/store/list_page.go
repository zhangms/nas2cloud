package store

//
//import (
//	"errors"
//	"github.com/gofiber/fiber/v2"
//	"nas2cloud/api/base"
//	"nas2cloud/libs"
//	"nas2cloud/libs/vfs"
//	"nas2cloud/res"
//	"nas2cloud/svc/storage"
//	"net/http"
//	"net/url"
//	"path"
//)
//
//type item struct {
//	Name    string
//	Type    string
//	Value   string
//	Size    string
//	ModTime string
//	Preview string
//}
//
//type page struct {
//	Title       string
//	ParentName  string
//	ParentValue string
//	CurrentName string
//	Items       []*item
//}
//
//func ListPage(c *fiber.Ctx) error {
//	fullPath, _ := url.QueryUnescape(c.Query("path", "/"))
//	username := "zms"
//	info, err := storage.Info(username, fullPath)
//	if err != nil {
//		return base.SendErrorPage(c, http.StatusBadRequest, err)
//	}
//	if info.Type != vfs.ObjectTypeDir {
//		return base.SendErrorPage(c, http.StatusForbidden, errors.New("not support"))
//	}
//	walk, _ := storage.Walk(username, fullPath, "fileName", int64(0),int64(10000))
//	data, err := createNavPage(fullPath, walk)
//	if err != nil {
//		return base.SendErrorPage(c, http.StatusInternalServerError, err)
//	}
//	return base.SendPage(c, data)
//}
//
//func createNavPage(fullPath string, infos []*vfs.ObjectInfo) ([]byte, error) {
//	dir, file := path.Split(path.Clean(fullPath))
//	p := &page{
//		ParentName:  libs.If(dir == "" || dir == "/", ".", "."+path.Clean(dir)).(string),
//		ParentValue: libs.If(dir == "" || dir == "/", "/", path.Clean(dir)).(string),
//		CurrentName: file,
//		Items: func() []*item {
//			ret := make([]*item, 0)
//			for _, o := range infos {
//				ret = append(ret, &item{
//					Name:    o.Name,
//					Type:    string(o.Type),
//					Value:   o.Path,
//					Size:    libs.If(o.Type == vfs.ObjectTypeDir, "", libs.ReadableDataSize(o.Size)).(string),
//					ModTime: o.ModTime.Format("2006-01-02"),
//					Preview: o.Preview,
//				})
//			}
//			return ret
//		}(),
//	}
//	return res.ParseText("store.html", p)
//}
