package res

import (
	"embed"
	"path"
)

//go:embed embed
var res embed.FS

func Read(fileName string) ([]byte, error) {
	return res.ReadFile(path.Join("embed", fileName))
}

func ReadByEnv(env string, fileName string) ([]byte, error) {
	return Read("env/" + env + "/" + fileName)
}
