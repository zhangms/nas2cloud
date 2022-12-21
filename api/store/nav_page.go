package store

import (
	"nas2cloud/libs"
	"nas2cloud/res"
	"nas2cloud/svc/storage/external"
	"nas2cloud/svc/storage/store"
	"path"
	"strings"
)

type navItem struct {
	Name  string
	Type  string
	Value string
}

type navPage struct {
	Title       string
	ParentName  string
	ParentValue string
	CurrentName string
	Items       []*navItem
}

func createNavPage(fullPath string, infos []*store.ObjectInfo) ([]byte, error) {
	dir, file := path.Split(path.Clean(fullPath))
	page := &navPage{
		ParentName: libs.IF(dir == "" || dir == "/" || dir == external.Protocol,
			func() any {
				return "."
			},
			func() any {
				p := path.Clean(dir)
				if strings.Index(p, external.Protocol) == 0 {
					return "./" + p[len(external.Protocol):]
				}
				return p
			}).(string),
		ParentValue: libs.If(dir == "" || dir == "/" || dir == external.Protocol, "/", path.Clean(dir)).(string),
		CurrentName: file,
		Items: func() []*navItem {
			ret := make([]*navItem, 0)
			for _, o := range infos {
				ret = append(ret, &navItem{
					Name:  o.Name,
					Type:  string(o.Type),
					Value: o.Path,
				})
			}
			return ret
		}(),
	}
	return res.ParseText("store.html", page)
}
