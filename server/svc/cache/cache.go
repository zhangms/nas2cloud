package cache

import (
	"context"
	"nas2cloud/libs/logger"
	"time"

	"github.com/go-redis/redis/v9"
)

const DefaultExpireTime = time.Minute * 10

func printerr(err error) {
	if err != nil {
		logger.ErrorStacktrace(err)
	}
}

func Get(key string) (string, error) {
	str, err := DefaultClient().Get(context.Background(), key).Result()
	if err == redis.Nil {
		return "", nil
	}
	if err != nil {
		printerr(err)
		return "", err
	}
	return str, nil
}

func Del(key string) (int64, error) {
	result, err := DefaultClient().Del(context.Background(), key).Result()
	printerr(err)
	return result, err
}

func MGet(keys ...string) ([]any, error) {
	if len(keys) == 0 {
		return []any{}, nil
	}
	result, err := DefaultClient().MGet(context.Background(), keys...).Result()
	printerr(err)
	return result, err
}

func SetNX(key string, value string) (bool, error) {
	result, err := DefaultClient().SetNX(context.Background(), key, value, 0).Result()
	printerr(err)
	return result, err
}

func SetNXExpire(key string, value string, expiration time.Duration) (bool, error) {
	result, err := DefaultClient().SetNX(context.Background(), key, value, expiration).Result()
	printerr(err)
	return result, err
}

func Set(key string, value string) (string, error) {
	result, err := DefaultClient().Set(context.Background(), key, value, 0).Result()
	printerr(err)
	return result, err
}

func SetExpire(key string, value string, expiration time.Duration) (string, error) {
	result, err := DefaultClient().Set(context.Background(), key, value, expiration).Result()
	printerr(err)
	return result, err
}

func Exists(key ...string) (int64, error) {
	result, err := DefaultClient().Exists(context.Background(), key...).Result()
	printerr(err)
	return result, err
}

func LLen(key string) (int64, error) {
	result, err := DefaultClient().LLen(context.Background(), key).Result()
	printerr(err)
	return result, err
}

func LRange(key string, start int64, stop int64) ([]string, error) {
	result, err := DefaultClient().LRange(context.Background(), key, start, stop).Result()
	printerr(err)
	return result, err
}

func ZCard(key string) (int64, error) {
	result, err := DefaultClient().ZCard(context.Background(), key).Result()
	printerr(err)
	return result, err
}

func ZRange(key string, start int64, stop int64) ([]string, error) {
	result, err := DefaultClient().ZRange(context.Background(), key, start, stop).Result()
	printerr(err)
	return result, err
}

func ZRevRange(key string, start int64, stop int64) ([]string, error) {
	result, err := DefaultClient().ZRevRange(context.Background(), key, start, stop).Result()
	printerr(err)
	return result, err
}

func ZAdd(key string, score float64, member string) (int64, error) {
	result, err := DefaultClient().ZAdd(context.Background(), key, redis.Z{
		Score:  score,
		Member: member,
	}).Result()
	printerr(err)
	return result, err
}

func ZRem(key string, members ...any) (int64, error) {
	result, err := DefaultClient().ZRem(context.Background(), key, members...).Result()
	printerr(err)
	return result, err
}
