package res

import (
	"embed"
	"nas2cloud/env"
	"path"
)

//go:embed embed
var res embed.FS

func ReadData(fileName string) ([]byte, error) {
	return res.ReadFile(path.Join("embed", fileName))
}

func ReadEnvConfig(fileName string) ([]byte, error) {
	return ReadData("env/" + env.GetProfileActive() + "/" + fileName)
}
