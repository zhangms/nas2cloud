package es

import (
	_ "embed"
	"encoding/json"
	"fmt"
	"nas2cloud/libs/logger"
	"testing"
)

func TestCreateIndex(t *testing.T) {
	DoInit("dev")
	err := CreateIndex("test", nil)
	logger.Info(err)
}

func TestIndexExists(t *testing.T) {
	DoInit("dev")
	exists, err := IndexExists("test")
	fmt.Println(exists, err)
}

func TestDeleteIndex(t *testing.T) {
	DoInit("dev")
	err := DeleteIndex([]string{"test"})
	fmt.Println(err)
}

//go:embed test_dsl.json
var testDsl string

func TestSearch(t *testing.T) {
	DoInit("dev")
	dest := &SearchResult[map[string]any]{}
	err := Search("dev_files", []byte(testDsl), dest)
	if err != nil {
		t.Error(err)
	}
	data, _ := json.Marshal(dest)
	fmt.Println(string(data))
}
