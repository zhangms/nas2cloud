package env

import (
	"flag"
	"nas2cloud/libs/logger"
	"os"
	"strings"
)

var (
	profile = "dev"
	port    = 7001
	action  = "start"
)

var gitCommit, gitDate string

func init() {
	logger.Info("gitCommit", gitCommit, "gitDate", gitDate)
	args := os.Args[1:]
	if len(args) > 0 && strings.Contains(args[0], "-test") {
		action = "test"
		return
	}
	flag.StringVar(&profile, "profile", "dev", "")
	flag.StringVar(&action, "action", "start", "")
	flag.IntVar(&port, "port", 8080, "")
	flag.Parse()
	if !IsStarting() {
		return
	}
	logger.Info("starting profile active", profile)
}

func PrintDefaults() {
	flag.PrintDefaults()
}

func GetProfileActive() string {
	return profile
}

func IsStarting() bool {
	return action == "start"
}

func GetAction() string {
	return action
}

func GetPort() int {
	return port
}
