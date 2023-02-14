package cache

import (
	"encoding/json"
	"fmt"
	"github.com/go-redis/redis/v9"
	"nas2cloud/libs/logger"
	"nas2cloud/res"
	"strings"
)

var defaultClient *redis.Client

type Config struct {
	Addr     string
	Password string
	DB       int
}

func DoInit(env string) {
	data, _ := res.ReadByEnv(env, "redis.json")
	conf := &Config{}
	err := json.Unmarshal(data, conf)
	if err != nil {
		panic(err)
	}
	defaultClient = redis.NewClient(&redis.Options{
		Addr:     conf.Addr,
		Password: conf.Password,
		DB:       conf.DB,
	})
	logger.Info("redis config loaded...")
}

func DefaultClient() *redis.Client {
	return defaultClient
}

func Join(slot string, elems ...any) string {
	strElems := make([]string, 0)
	for _, k := range elems {
		strElems = append(strElems, fmt.Sprintf("%v", k))
	}
	return "{" + slot + "}:" + strings.Join(strElems, "_")
}
