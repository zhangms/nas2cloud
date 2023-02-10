package main

import (
	"fmt"
	"io/fs"
	"log"
	"nas2cloud/api"
	"nas2cloud/env"
	"nas2cloud/libs/logger"
	"os"
	"os/exec"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v2"
)

const pidFile = "nas2cloud.pid"

func main() {
	action := env.GetAction()
	switch action {
	case "start":
		start()
	case "stop":
		stop()
	default:
		log.Println("do nothing", action)
	}
}

func start() {
	_ = os.WriteFile(pidFile, []byte(strconv.Itoa(os.Getpid())), fs.ModePerm)
	defer os.Remove(pidFile)
	app := fiber.New(fiber.Config{
		BodyLimit: 1024 * 1024 * 1024, //1G
	})
	api.Register(app)
	go waitingSignal(app)
	err := app.Listen(fmt.Sprintf(":%d", env.GetPort()))
	if err != nil {
		logger.Error(err)
	}
}

func waitingSignal(app *fiber.App) {
	sig := make(chan os.Signal, 2)
	signal.Notify(sig, syscall.SIGTERM, syscall.SIGINT)
	for {
		select {
		case <-sig:
			logger.Warn("RECEIVE_TERM_SIGNAL", "system will shutdown...")
			err := app.Shutdown()
			logger.Warn("shutdown end", err)
			os.Exit(0)
		default:
			time.Sleep(time.Second)
		}
	}
}

func stop() {
	data, err := os.ReadFile(pidFile)
	if err != nil {
		logger.Error("not find pid file,cant stop", pidFile)
		return
	}
	pid := string(data)
	cmd := exec.Command("kill", pid)
	_, err = cmd.Output()
	if err != nil {
		logger.Error("stop error", err)
		return
	}
	logger.Info("stop signal send")
}
