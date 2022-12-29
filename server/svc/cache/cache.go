package cache

import (
	"context"
	"encoding/json"
	"github.com/go-redis/redis/v9"
	"time"
)

const defaultCacheDuration = time.Minute * 10

func Get(key string) (string, error) {
	str, err := client.Get(context.Background(), key).Result()
	if err == redis.Nil {
		return "", nil
	}
	if err != nil {
		return "", err
	}
	return str, nil
}

func ComputeIfAbsent(key string, f1 func(str string) (any, error), f2 func() (any, error)) (any, bool, error) {
	str, err := Get(key)
	if err != nil {
		return nil, false, err
	}
	if len(str) > 0 {
		r, e := f1(str)
		return r, true, e
	}
	ret, err := f2()
	if err != nil {
		return nil, false, err
	}
	data, err := json.Marshal(ret)
	if err != nil {
		return nil, false, err
	}
	_, err = Set(key, string(data))
	if err != nil {
		return nil, false, err
	}
	return ret, false, nil
}

func Del(key ...string) (int64, error) {
	return client.Del(context.Background(), key...).Result()
}

func Set(key string, value any) (string, error) {
	return client.Set(context.Background(), key, value, defaultCacheDuration).Result()
}

func Exists(key string) (bool, error) {
	count, err := client.Exists(context.Background(), key).Result()
	return count > 0, err
}

func RPush(key string, value ...any) (int64, error) {
	return client.RPush(context.Background(), key, value...).Result()
}
