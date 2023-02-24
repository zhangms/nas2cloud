package files

import (
	_ "embed"
	"encoding/json"
	"fmt"
	"nas2cloud/svc/es"
)

//go:embed es-mapper/files_index_query_image.json
var esQueryPhoto string

type photoSearch struct {
}

func (p *photoSearch) search() {
	mp := make(map[string]any)
	err := es.Search("dev_files", []byte(esQueryPhoto), &mp)
	fmt.Println(err)
	data, _ := json.Marshal(&mp)
	fmt.Println(string(data))
}
