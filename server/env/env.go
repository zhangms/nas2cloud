package env

import (
	"flag"
	"fmt"
	"nas2cloud/libs/logger"
	"os"
	"strings"
)

var profile = "dev"
var port = 7001
var action = "start"
var testing = false

func init() {
	args := os.Args[1:]
	fmt.Println(args)
	if len(args) > 0 && strings.Contains(args[0], "-test") {
		testing = true
		return
	}
	flag.StringVar(&profile, "profile", "dev", "")
	flag.StringVar(&action, "action", "start", "")
	flag.IntVar(&port, "port", 8080, "")
	flag.Parse()
	if !IsActionStart() {
		return
	}
	flag.PrintDefaults()
	logger.Info("profile active", profile)
}

func GetProfileActive() string {
	return profile
}

func IsActionStart() bool {
	return action == "start" && !IsTesting()
}

func GetAction() string {
	return action
}

func GetPort() int {
	return port
}

func IsTesting() bool {
	return testing
}
