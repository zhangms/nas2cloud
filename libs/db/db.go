package db

import (
	"database/sql"
	"time"
)

type Config struct {
	Driver          string
	Url             string
	ConnMaxLifeTime time.Duration
	MaxOpenConns    int
	MaxIdleConns    int
}

func Open(conf *Config) (*sql.DB, error) {
	rdb, err := sql.Open(conf.Driver, conf.Url)
	if err != nil {
		return nil, err
	}
	if conf.ConnMaxLifeTime > 0 {
		rdb.SetConnMaxLifetime(conf.ConnMaxLifeTime)
	}
	if conf.MaxOpenConns > 0 {
		rdb.SetMaxOpenConns(conf.MaxOpenConns)
	}
	if conf.MaxIdleConns > 0 {
		rdb.SetMaxIdleConns(conf.MaxIdleConns)
	}
	return rdb, nil
}
