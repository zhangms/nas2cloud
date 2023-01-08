package env

import (
	"flag"
	"nas2cloud/libs/logger"
	"os"
)

var profile = "dev"
var port = 7001
var action = "start"

func init() {
	args := os.Args[1:]
	if len(args) > 0 && args[0] == "-test.v" {
		return
	}
	flag.StringVar(&profile, "profile", "dev", "")
	flag.StringVar(&action, "action", "start", "")
	flag.IntVar(&port, "port", 8080, "")
	flag.Parse()
	if IsActionStart() {
		flag.PrintDefaults()
		logger.Info("profile active", profile)
	}
}

func GetProfileActive() string {
	return profile
}

func IsActionStart() bool {
	return action == "start"
}

func GetAction() string {
	return action
}

func GetPort() int {
	return port
}
