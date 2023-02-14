package main

import (
	"nas2cloud/cmd"
	"nas2cloud/libs/logger"
	"os"
)

var app = cmd.NewApp()

func main() {
	if err := app.Run(os.Args); err != nil {
		logger.Fatal(err)
	}
}
