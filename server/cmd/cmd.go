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
	}
	return app
}

func pidFile() string {
	dir := filepath.Dir(os.Args[0])
	if strings.Index(dir, "go-build") > 0 {
		return "nas2cloud.pid"
	}
	return filepath.Join(dir, "nas2cloud.pid")
}
