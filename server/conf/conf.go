package conf

import (
	"encoding/json"
	"nas2cloud/libs/logger"
	"nas2cloud/res"
	"strconv"
)

var configMap = make(map[string]string)

func init() {
	data, err := res.ReadEnvConfig("conf.json")
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

func GetIntValue(key string, defaultValue int) int {
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
