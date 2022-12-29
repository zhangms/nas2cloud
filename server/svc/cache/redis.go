package cache

import (
	"encoding/json"
	"github.com/go-redis/redis/v9"
	"nas2cloud/res"
)

var client *redis.Client

type Config struct {
	Addr     string
	Password string
	DB       int
}

func init() {
	data, _ := res.ReadData("redis.json")
	conf := &Config{}
	_ = json.Unmarshal(data, conf)
	client = redis.NewClient(&redis.Options{
		Addr:     conf.Addr,
		Password: conf.Password,
		DB:       conf.DB,
	})
}
