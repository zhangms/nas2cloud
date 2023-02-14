package cmd

import (
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

const (
	defaultPort    = 8080
	defaultProfile = "dev"
)

var startFlagPort = &cli.IntFlag{
	Name:        "port",
	Usage:       "http server port",
	DefaultText: fmt.Sprintf("%d", defaultPort),
}

var startFlagProfile = &cli.StringFlag{
	Name:        "profile",
	Usage:       "environment profile",
	DefaultText: defaultProfile,
}

var startCommand = &cli.Command{
	Name:  "start",
	Usage: "start server",
	Flags: []cli.Flag{
		startFlagPort, startFlagProfile,
	},
	Action: start,
}

func start(context *cli.Context) error {
	profile := defaultProfile
	port := defaultPort
	if context.IsSet(startFlagProfile.Name) {
		profile = context.String(startFlagProfile.Name)
	}
	if context.IsSet(startFlagPort.Name) {
		port = context.Int(startFlagPort.Name)
	}

	logger.Info("profile active", profile)
	logger.Info("http port", port)
	logger.Info("gitCommit", gitCommit, gitDate)
	res.DoInit(profile)
	cache.DoInit(profile)
	files.DoInit(profile)
	user.DoInit(profile)
	fiberApp := fiber.New(fiber.Config{
		BodyLimit: 1024 * 1024 * 1024, //1G
	})
	api.DoInit(profile, fiberApp)
	startError.Store(false)
	go waitingSignal(fiberApp)
	err := fiberApp.Listen(fmt.Sprintf(":%d", port))
	if err != nil {
		startError.Store(true)
		return err
	}
	return nil
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
			logger.Error("start error exit")
			break
		}
		select {
		case <-sig:
			logger.Warn("RECEIVE_TERM_SIGNAL", "system will shutdown...")
			_ = os.Remove(pid)
			err := fiberApp.Shutdown()
			logger.Warn("SHUTDOWN", err)
			os.Exit(0)
		default:
			time.Sleep(time.Millisecond * 10)
		}
	}
}
