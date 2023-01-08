package db

import (
	"database/sql"
	"time"
)

type config struct {
	Driver          string
	Url             string
	ConnMaxLifeTime time.Duration
	MaxOpenConns    int
	MaxIdleConns    int
}

func open(conf *config) (*sql.DB, error) {
	sqlDb, err := sql.Open(conf.Driver, conf.Url)
	if err != nil {
		return nil, err
	}
	if conf.ConnMaxLifeTime > 0 {
		sqlDb.SetConnMaxLifetime(conf.ConnMaxLifeTime)
	}
	if conf.MaxOpenConns > 0 {
		sqlDb.SetMaxOpenConns(conf.MaxOpenConns)
	}
	if conf.MaxIdleConns > 0 {
		sqlDb.SetMaxIdleConns(conf.MaxIdleConns)
	}
	return sqlDb, nil
}
