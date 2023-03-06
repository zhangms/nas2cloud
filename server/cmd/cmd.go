package cmd

import (
	"github.com/urfave/cli/v2"
	"nas2cloud/libs"
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
	return libs.Resource("nas2cloud.pid")
}
