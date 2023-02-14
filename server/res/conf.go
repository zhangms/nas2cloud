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
		logger.Error("conf.json read error", err)
		return
	}
	err = json.Unmarshal(data, &configMap)
	if err != nil {
		logger.Error("conf.json Unmarshal error", err)
		return
	}
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
