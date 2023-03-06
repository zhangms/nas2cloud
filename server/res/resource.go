package res

import (
	"embed"
	"nas2cloud/libs"
	"os"
	"path"
	"path/filepath"
)

//go:embed embed
var res embed.FS

func Read(fileName string) ([]byte, error) {
	return res.ReadFile(path.Join("embed", fileName))
}

func ReadByEnv(env string, fileName string) ([]byte, error) {
	return os.ReadFile(filepath.Join(libs.Resource(env), fileName))
}
