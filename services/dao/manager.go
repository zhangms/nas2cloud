package dao

import (
	"database/sql"
	"errors"
	"fmt"
	_ "github.com/go-sql-driver/mysql"
	"nas2cloud/libs/db"
	"time"
)

var dataSources = make(map[string]*sql.DB)

func GetOrConnectDb(dataSourceName string, host string, dbName string, dbUser string, dbPass string) (*sql.DB, error) {
	sqlDb := dataSources[dataSourceName]
	if sqlDb != nil {
		return sqlDb, nil
	}
	conf := &db.ConnConfig{
		Driver:          "mysql",
		Url:             fmt.Sprintf("%s:%s@tcp(%s)/%s", dbUser, dbPass, host, dbName),
		ConnMaxLifeTime: time.Minute * 3,
		MaxOpenConns:    10,
		MaxIdleConns:    10,
	}
	sqlDb, err := db.Connect(conf)
	if err != nil {
		return nil, err
	}
	dataSources[dataSourceName] = sqlDb
	return sqlDb, nil
}

func GetDb(dataSourceName string) (*sql.DB, error) {
	sqlDb := dataSources[dataSourceName]
	if sqlDb != nil {
		return sqlDb, nil
	}
	return nil, errors.New("db not connected")
}
