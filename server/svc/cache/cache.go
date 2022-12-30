package cache

import (
	"context"
	"github.com/go-redis/redis/v9"
	"time"
)

const DefaultExpireTime = time.Minute * 10

func Get(key string) (string, error) {
	str, err := DefaultClient().Get(context.Background(), key).Result()
	if err == redis.Nil {
		return "", nil
	}
	if err != nil {
		return "", err
	}
	return str, nil
}

func MGet(keys ...string) ([]any, error) {
	if len(keys) == 0 {
		return []any{}, nil
	}
	return DefaultClient().MGet(context.Background(), keys...).Result()
}

func SetNX(key string, value string) (bool, error) {
	return DefaultClient().SetNX(context.Background(), key, value, 0).Result()
}

func SetNXExpire(key string, value string, expiration time.Duration) (bool, error) {
	return DefaultClient().SetNX(context.Background(), key, value, expiration).Result()
}

func Set(key string, value string) (string, error) {
	return DefaultClient().Set(context.Background(), key, value, 0).Result()
}

func Exists(key ...string) (int64, error) {
	return DefaultClient().Exists(context.Background(), key...).Result()
}

func LLen(key string) (int64, error) {
	return DefaultClient().LLen(context.Background(), key).Result()
}

func LRange(key string, start int64, stop int64) ([]string, error) {
	return DefaultClient().LRange(context.Background(), key, start, stop).Result()
}

func ZCard(key string) (int64, error) {
	return DefaultClient().ZCard(context.Background(), key).Result()
}

func ZRange(key string, start int64, stop int64) ([]string, error) {
	return DefaultClient().ZRange(context.Background(), key, start, stop).Result()
}

func ZRevRange(key string, start int64, stop int64) ([]string, error) {
	return DefaultClient().ZRevRange(context.Background(), key, start, stop).Result()
}

func ZAdd(key string, score float64, member string) (int64, error) {
	return DefaultClient().ZAdd(context.Background(), key, redis.Z{
		Score:  score,
		Member: member,
	}).Result()
}
