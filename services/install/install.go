package install

type Config struct {
	DbName string `json:"dbName"`
	DbUser string `json:"dbUser"`
	DbPass string `json:"dbPass"`
}

func Install(config *Config) {
}
