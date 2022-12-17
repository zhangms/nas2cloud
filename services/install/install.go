package install

import "nas2cloud/services/dao"

type Config struct {
	DbAddress string `json:"db_address"`
	DbName    string `json:"db_name"`
	DbUser    string `json:"db_user"`
	DbPass    string `json:"db_pass"`
}

func Install(config *Config) {
	dao.GetOrConnectDb("install", config.DbAddress, config.DbName, config.DbUser, config.DbPass)
}
