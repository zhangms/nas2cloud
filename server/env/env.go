package env

import (
	"flag"
	"nas2cloud/libs/logger"
)

var profile string = "default"

func init() {
	flag.StringVar(&profile, "profile", "default", "")
	flag.Parse()
	logger.Info("profile active", profile)
}

func GetProfileActive() string {
	return profile
}
