package cmd

import (
	"github.com/urfave/cli/v2"
	"nas2cloud/libs/logger"
	"os"
	"os/exec"
	"runtime"
)

var stopCommand = &cli.Command{
	Name:   "stop",
	Usage:  "stop server",
	Action: stop,
}

func stop(context *cli.Context) error {
	data, err := os.ReadFile(pidFile())
	if err != nil {
		logger.Error("not find pid file,cant stop", pidFile())
		return nil
	}
	pid := string(data)
	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		cmd = exec.Command("tskill", pid)
	} else {
		cmd = exec.Command("kill", pid)
	}
	_, err = cmd.Output()
	if err != nil {
		logger.Error("stop error", err)
		return nil
	}
	logger.Info("stop signal send")
	return nil
}
