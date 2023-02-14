package cmd

import (
	"github.com/urfave/cli/v2"
)

var gitCommit, gitDate string

func NewApp() *cli.App {
	var app = cli.NewApp()
	app.Name = "nas2cloud"
	app.Usage = "server"
	app.Commands = []*cli.Command{
		startCommand,
		stopCommand,
	}
	return app
}

func pidFile() string {
	//return filepath.Join(filepath.Dir(os.Args[0]), "nas2cloud.pid")
	return "nas2cloud.pid"
}
