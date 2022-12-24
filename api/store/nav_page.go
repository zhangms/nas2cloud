package store

import (
	"nas2cloud/libs"
	"nas2cloud/libs/vfs"
	"nas2cloud/res"
	"path"
)

type navItem struct {
	Name    string
	Type    string
	Value   string
	Size    string
	ModTime string
	Preview string
}

type navPage struct {
	Title       string
	ParentName  string
	ParentValue string
	CurrentName string
	Items       []*navItem
}

func createNavPage(fullPath string, infos []*vfs.ObjectInfo) ([]byte, error) {
	dir, file := path.Split(path.Clean(fullPath))
	page := &navPage{
		ParentName:  libs.If(dir == "" || dir == "/", ".", "."+path.Clean(dir)).(string),
		ParentValue: libs.If(dir == "" || dir == "/", "/", path.Clean(dir)).(string),
		CurrentName: file,
		Items: func() []*navItem {
			ret := make([]*navItem, 0)
			for _, o := range infos {
				ret = append(ret, &navItem{
					Name:    o.Name,
					Type:    string(o.Type),
					Value:   o.Path,
					Size:    libs.If(o.Type == vfs.ObjectTypeDir, "", libs.ReadableDataSize(o.Size)).(string),
					ModTime: o.ModTime.Format("2006-01-02"),
					Preview: o.Preview,
				})
			}
			return ret
		}(),
	}
	return res.ParseText("store.html", page)
}
