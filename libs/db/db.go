package db

import (
	"database/sql"
	"time"
)

type ConnConfig struct {
	Driver          string
	Url             string
	ConnMaxLifeTime time.Duration
	MaxOpenConns    int
	MaxIdleConns    int
}

func Connect(conf *ConnConfig) (*sql.DB, error) {
	db, err := sql.Open(conf.Driver, conf.Url)
	if err != nil {
		return nil, err
	}
	if conf.ConnMaxLifeTime > 0 {
		db.SetConnMaxLifetime(conf.ConnMaxLifeTime)
	}
	if conf.MaxOpenConns > 0 {
		db.SetMaxOpenConns(conf.MaxOpenConns)
	}
	if conf.MaxIdleConns > 0 {
		db.SetMaxIdleConns(conf.MaxIdleConns)
	}
	return db, nil
}
