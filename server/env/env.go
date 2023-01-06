package env

import (
	"flag"
	"nas2cloud/libs/logger"
	"os"
)

var profile = "default"

func init() {
	args := os.Args[1:]
	if len(args) > 0 && args[0] == "-test.v" {
		return
	}
	flag.StringVar(&profile, "profile", "default", "")
	flag.PrintDefaults()
	flag.Parse()
	logger.Info("profile active", profile)
}

func GetProfileActive() string {
	return profile
}
