package res

import (
	"embed"
	"path"
)

//go:embed embed
var res embed.FS

func ReadData(fileName string) ([]byte, error) {
	return res.ReadFile(path.Join("embed", fileName))
}
