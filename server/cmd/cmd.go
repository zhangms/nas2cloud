package cmd

import (
	"github.com/urfave/cli/v2"
	"os"
	"path/filepath"
	"strings"
)

var gitCommit, gitDate string

func NewApp() *cli.App {
	var app = cli.NewApp()
	app.Name = "nas2cloud"
	app.Usage = "server"
	app.Commands = []*cli.Command{
		startCommand,
		stopCommand,
		configCommand,
		json2dartCommand,
	}
	return app
}

func pidFile() string {
	return resource("nas2cloud.pid")
}

func resource(name string) string {
	dir := filepath.Dir(os.Args[0])
	if strings.Index(dir, "go-build") > 0 || strings.Index(dir, "GoLand") > 0 {
		return name
	}
	return filepath.Join(dir, name)
}
