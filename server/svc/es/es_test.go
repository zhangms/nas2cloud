package es

import (
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
	err := DeleteIndex("test")
	fmt.Println(err)
}
