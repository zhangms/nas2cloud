package libs

import (
	"os"
	"path/filepath"
	"strings"
)

func Resource(name string) string {
	dir := filepath.Dir(os.Args[0])
	if strings.Index(dir, "go-build") > 0 || strings.Index(dir, "GoLand") > 0 {
		return name
	}
	return filepath.Join(dir, name)
}
