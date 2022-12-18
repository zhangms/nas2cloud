package storage

import (
	"encoding/json"
	"errors"
	"nas2cloud/libs"
	"nas2cloud/res"
	"path"
	"strings"
)

const externalProtocol = "external://"

type external struct {
	Name      string `json:"name"`
	Type      string `json:"type"`
	Path      string `json:"path"`
	Authorize string `json:"authorize"`
}

func (e *external) Authorized(username string) bool {
	if e.Authorize == "ALL" {
		return true
	}
	arr := strings.Split(e.Authorize, ",")
	for _, v := range arr {
		if strings.TrimSpace(v) == username {
			return true
		}
	}
	return false
}

var externals map[string]*external

func init() {
	externals = make(map[string]*external)
	data, _ := res.ReadData("external.json")
	extList := make([]*external, 0)
	_ = json.Unmarshal(data, &extList)
	for _, e := range extList {
		externals[e.Name] = e
	}
}

type externalStore struct {
}

var storeExternal = &externalStore{}

// fullPath : external://ExternalName/file
func (e *externalStore) list(fullPath string) []*ObjectInfo {
	externalName, file, err := e.split(fullPath)
	if err != nil {
		return emptyObjectInfos()
	}
	ext := externals[externalName]
	if ext == nil {
		return emptyObjectInfos()
	}
	if ext.Type == "local" {
		return storeLocal.list(path.Join(ext.Path, file))
	}
	return emptyObjectInfos()
}

func (e *externalStore) info(fullPath string) *ObjectInfo {
	externalName, file, err := e.split(fullPath)
	if err != nil {
		return nil
	}
	ext := externals[externalName]
	if ext == nil {
		return nil
	}
	if ext.Type == "local" {
		return storeLocal.info(path.Join(ext.Path, file))
	}
	return nil
}

func (e *externalStore) split(fullPath string) (externalName string, file string, err error) {
	externalName = ""
	file = ""
	err = nil
	if strings.Index(fullPath, externalProtocol) != 0 {
		err = errors.New("not valid external path")
		return
	}
	p := fullPath[len(externalProtocol):]
	arr := strings.SplitN(p, "/", 2)
	externalName = arr[0]
	file = libs.If(len(arr) > 1, func() any {
		return arr[1]
	}, func() any {
		return ""
	}).(string)
	return
}
