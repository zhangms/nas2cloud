package cmd

import (
	"github.com/urfave/cli/v2"
	"nas2cloud/json2dart"
)

var json2dartCommand = &cli.Command{
	Name:  "json2dart",
	Usage: "convert json file to dart class",
	Flags: []cli.Flag{
		&cli.StringFlag{
			Name:  "className",
			Usage: "dart class name",
		},
		&cli.StringFlag{
			Name:  "in",
			Usage: "input json file path",
		},
		&cli.StringFlag{
			Name:  "out",
			Usage: "output dart directory",
		},
	},
	Action: func(context *cli.Context) error {
		if !context.IsSet("in") || !context.IsSet("out") || !context.IsSet("className") {
			return nil
		}
		return json2dart.Exec(context.String("in"), context.String("out"), context.String("className"))
	},
}
