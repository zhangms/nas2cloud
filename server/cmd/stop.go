package cmd

import (
	"github.com/urfave/cli/v2"
	"nas2cloud/libs/logger"
	"os"
	"strconv"
	"syscall"
)

var stopCommand = &cli.Command{
	Name:   "stop",
	Usage:  "stop server",
	Action: stop,
}

func stop(cliCtx *cli.Context) error {
	data, err := os.ReadFile(pidFile())
	if err != nil {
		logger.Error("not find pid file,cant stop", pidFile())
		return nil
	}
	pid, err := strconv.Atoi(string(data))
	if err != nil {
		logger.Error("pid error :", err)
		return nil
	}
	process, err := os.FindProcess(pid)
	if err != nil {
		logger.Error("cant find pid", err)
		return nil
	}
	if err = process.Signal(syscall.SIGINT); err != nil {
		e2 := process.Kill()
		_ = os.Remove(pidFile())
		logger.Error("send signal error and kill", err, e2)
	} else {
		logger.Info("stop signal send")
	}
	return nil
}
