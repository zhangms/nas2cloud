package api

import (
	"fmt"
	"net/url"
	"testing"
)

func TestX(t *testing.T) {
	fmt.Println(url.QueryEscape("/app"))
}
