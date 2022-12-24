package dao

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	_ "github.com/go-sql-driver/mysql"
	"nas2cloud/libs/db"
	"nas2cloud/libs/logger"
	"nas2cloud/res"
	"sync"
	"time"
)

const defaultDatabaseId = "default"

var opened = &sync.Map{}

type Config struct {
	Id       string
	Name     string
	Address  string
	User     string
	Password string
}

func init() {
	data, err := res.ReadData("db.json")
	if err != nil {
		logger.ErrorStacktrace(err)
		panic(err)
	}
	type defaultDbConfig struct {
		User     string `json:"user"`
		Password string `json:"password"`
		Database string `json:"database"`
		Address  string `json:"address"`
	}
	conf := &defaultDbConfig{}
	_ = json.Unmarshal(data, conf)
	_, err = OpenDB(&Config{
		Id:       defaultDatabaseId,
		Name:     conf.Database,
		User:     conf.User,
		Password: conf.Password,
		Address:  conf.Address,
	})
	if err != nil {
		logger.ErrorStacktrace(err)
		panic(err)
	}
	logger.Info("default database init end")
}

func OpenDB(conf *Config) (*sql.DB, error) {
	loaded, ok := opened.Load(conf.Id)
	if ok {
		return loaded.(*sql.DB), nil
	}
	sqlDb, err := db.Open(&db.Config{
		Driver:          "mysql",
		Url:             fmt.Sprintf("%s:%s@tcp(%s)/%s", conf.User, conf.Password, conf.Address, conf.Name),
		ConnMaxLifeTime: time.Minute * 3,
		MaxOpenConns:    10,
		MaxIdleConns:    10,
	})
	if err != nil {
		return nil, err
	}
	opened.Store(conf.Id, sqlDb)
	return sqlDb, nil
}

func DB() *sql.DB {
	sqlDb, _ := GetDB(defaultDatabaseId)
	return sqlDb
}

func GetDB(id string) (*sql.DB, error) {
	loaded, ok := opened.Load(id)
	if ok {
		return loaded.(*sql.DB), nil
	}
	return nil, errors.New("db not open:" + id)
}

func CloseDB(id string) error {
	loaded, ok := opened.LoadAndDelete(id)
	if ok {
		return loaded.(*sql.DB).Close()
	}
	return nil
}
