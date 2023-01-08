package cache

import (
	"encoding/json"
	"fmt"
	"github.com/go-redis/redis/v9"
	"nas2cloud/res"
	"strings"
)

var defaultClient *redis.Client

type Config struct {
	Addr     string
	Password string
	DB       int
}

func init() {
	data, _ := res.ReadEnvConfig("redis.json")
	conf := &Config{}
	_ = json.Unmarshal(data, conf)
	defaultClient = redis.NewClient(&redis.Options{
		Addr:     conf.Addr,
		Password: conf.Password,
		DB:       conf.DB,
	})
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
