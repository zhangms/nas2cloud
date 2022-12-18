package storage

import (
	"encoding/json"
	"nas2cloud/res"
)

type external struct {
	Name      string `json:"name"`
	Type      string `json:"type"`
	Path      string `json:"path"`
	Authorize string `json:"authorize"`
}

var externals []*external

func init() {
	data, _ := res.ReadData("external.json")
	extList := make([]*external, 0)
	_ = json.Unmarshal(data, &extList)
	externals = extList
}

func Ext() []*external {
	return externals
}
