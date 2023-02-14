package res

import (
	"encoding/json"
	"nas2cloud/libs/logger"
	"strconv"
)

var configMap = make(map[string]string)

func DoInit(env string) {
	data, err := ReadByEnv(env, "conf.json")
	if err != nil {
		panic(err)
	}
	err = json.Unmarshal(data, &configMap)
	if err != nil {
		panic(err)
	}
	logger.Info("res config loaded...")
}

func GetInt(key string, defaultValue int) int {
	value, ok := configMap[key]
	if !ok {
		return defaultValue
	}
	v, err := strconv.Atoi(value)
	if err != nil {
		return defaultValue
	}
	return v
}

func GetString(key string) string {
	value, _ := configMap[key]
	return value
}
