package resources

import (
	"embed"
	"path"
)

//go:embed res
var res embed.FS

func ReadData(fileName string) ([]byte, error) {
	return res.ReadFile(path.Join("res", fileName))
}
