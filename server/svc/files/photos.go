package files

import (
	_ "embed"
	"fmt"
	"nas2cloud/svc/es"
)

//go:embed es-mapper/files_index_query_image.json
var esQueryPhoto string

type photoSearch struct {
}

func (p *photoSearch) search() {
	err := es.Search("dev_files", []byte(esQueryPhoto), nil)
	fmt.Println(err)
}
