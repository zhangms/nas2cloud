package cmd

import (
	"context"
	"fmt"
	"github.com/urfave/cli/v2"
	"nas2cloud/api"
	"nas2cloud/libs/logger"
	"nas2cloud/res"
	"nas2cloud/svc/cache"
	"nas2cloud/svc/files"
	"nas2cloud/svc/user"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"
)

type startFlags struct {
	port    int
	profile string
}

var defaultFlags = startFlags{
	port:    8080,
	profile: "dev",
}

var startFlagPort = &cli.IntFlag{
	Name:        "port",
	Usage:       "http server port",
	DefaultText: fmt.Sprintf("%d", defaultFlags.port),
}

var startFlagProfile = &cli.StringFlag{
	Name:        "profile",
	Usage:       "environment profile",
	DefaultText: defaultFlags.profile,
}

var startCommand = &cli.Command{
	Name:  "start",
	Usage: "start server",
	Flags: []cli.Flag{
		startFlagPort, startFlagProfile,
	},
	Action: start,
}

var cancelFunc context.CancelFunc

func start(cliCtx *cli.Context) error {
	ctx, cancel := context.WithCancel(context.Background())
	cancelFunc = cancel
	flags := getFlags(cliCtx)
	logger.Info("profile active", flags.profile)
	logger.Info("http port", flags.port)
	logger.Info("gitCommit", gitCommit, gitDate)
	res.DoInit(flags.profile)
	cache.DoInit(flags.profile)
	files.DoInit(flags.profile, ctx)
	user.DoInit(flags.profile)
	api.StartHttpServer(flags.profile, flags.port)
	return waitingSignal()
}

func getFlags(cliCtx *cli.Context) startFlags {
	flags := defaultFlags
	if cliCtx.IsSet(startFlagProfile.Name) {
		flags.profile = cliCtx.String(startFlagProfile.Name)
	}
	if cliCtx.IsSet(startFlagPort.Name) {
		flags.port = cliCtx.Int(startFlagPort.Name)
	}
	return flags
}

func waitingSignal() error {
	pid := pidFile()
	_, err := os.Stat(pid)
	if err == nil || os.IsExist(err) {
		logger.Error("pid file exists already, system will exit!")
		shutdown()
		return nil
	}
	if err := os.WriteFile(pid, []byte(strconv.Itoa(os.Getpid())), os.ModePerm); err != nil {
		logger.Warn("pid file write error, system will exit!", err)
		shutdown()
		return nil
	}
	defer func() {
		_ = os.Remove(pid)
	}()
	signals := make(chan os.Signal, 2)
	signal.Notify(signals, syscall.SIGTERM, syscall.SIGINT)
	for {
		select {
		case <-signals:
			logger.Warn("RECEIVE_TERM_SIGNAL", "system will shutdown...")
			shutdown()
		case err := <-api.Done():
			logger.Warn("SHUTDOWN", err)
			return nil
		}
	}
}

func shutdown() {
	cancelFunc()
	time.Sleep(time.Millisecond * 20)
	if err := api.Shutdown(); err != nil {
		logger.Error("api server shutdown error")
	}

}
