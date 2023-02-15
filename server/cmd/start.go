package cmd

import (
	"context"
	"fmt"
	"github.com/gofiber/fiber/v2"
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
	"sync/atomic"
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
	fiberApp := fiber.New(fiber.Config{
		BodyLimit: 1024 * 1024 * 1024, //1G
	})
	api.DoInit(flags.profile, fiberApp)
	startError.Store(false)
	go waitingSignal(fiberApp)
	err := fiberApp.Listen(fmt.Sprintf(":%d", flags.port))
	if err != nil {
		startError.Store(true)
		return err
	}
	return nil
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

var startError = &atomic.Bool{}

func waitingSignal(fiberApp *fiber.App) {
	pid := pidFile()
	if err := os.WriteFile(pid, []byte(strconv.Itoa(os.Getpid())), os.ModePerm); err != nil {
		logger.Warn("pid file write error", err)
	}
	defer func() {
		_ = os.Remove(pid)
	}()
	sig := make(chan os.Signal, 2)
	signal.Notify(sig, syscall.SIGTERM, syscall.SIGINT)
	for {
		if startError.Load() {
			cancelFunc()
			logger.Error("start error exit")
			break
		}
		select {
		case <-sig:
			logger.Warn("RECEIVE_TERM_SIGNAL", "system will shutdown...")
			cancelFunc()
			_ = os.Remove(pid)
			err := fiberApp.ShutdownWithTimeout(time.Second)
			logger.Warn("SHUTDOWN", err)
		default:
			time.Sleep(time.Millisecond * 10)
		}
	}
}
