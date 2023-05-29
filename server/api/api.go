package api

import (
	"encoding/base64"
	"errors"
	"fmt"
	"nas2cloud/libs/errs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc/sign"
	"nas2cloud/svc/user"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	fiberLogger "github.com/gofiber/fiber/v2/middleware/logger"
)

var fiberApp *fiber.App
var done chan error

func StartHttpServer(env string, port int) {
	fiberApp = fiber.New(fiber.Config{
		BodyLimit: 1024 * 1024 * 1024, //1G
	})
	initCROS(env)
	initLogger(fiberApp)
	registerStatic(fiberApp)
	registerHandler(fiberApp)
	done = make(chan error)
	go func() {
		err := fiberApp.Listen(fmt.Sprintf(":%d", port))
		if err != nil {
			done <- err
		}
		close(done)
	}()
}

func Done() <-chan error {
	return done
}

func Shutdown() error {
	return fiberApp.Shutdown()
}

func initLogger(app *fiber.App) {
	app.Use(fiberLogger.New(fiberLogger.Config{
		Next:         nil,
		Done:         nil,
		Format:       "${time} [HTTP ] ${status}|${latency}|${user}|${method}|${path}\n",
		TimeFormat:   "2006/01/02 15:04:05.000000",
		TimeZone:     "Local",
		TimeInterval: 500 * time.Millisecond,
		Output:       logger.GetWriter(),
		CustomTags: map[string]fiberLogger.LogFunc{
			"user": func(output fiberLogger.Buffer, c *fiber.Ctx, data *fiberLogger.Data, extraParam string) (int, error) {
				u, _ := GetContextUser(c)
				if u != nil {
					return output.Write([]byte(u.Name))
				} else {
					return output.Write([]byte("nil"))
				}
			},
			"method8": func(output fiberLogger.Buffer, c *fiber.Ctx, data *fiberLogger.Data, extraParam string) (int, error) {
				return output.Write([]byte(fmt.Sprintf("%8s", c.Method())))
			},
		},
	}))
}

func registerStatic(app *fiber.App) {
	for _, b := range vfs.GetAllBucket() {
		if b.MountTypeLocal() {
			if b.Authorize() == "PUBLIC" {
				logger.Info("register static public", b.Dir(), b.Endpoint())
				app.All(b.Dir()+"/*.apk", func(ctx *fiber.Ctx) error {
					ctx.Set(fiber.HeaderContentType, "application/vnd.android.package-archive")
					return ctx.Next()
				})
				app.Static(b.Dir(), b.Endpoint(), fiber.Static{
					ByteRange: true,
				})
			} else {
				logger.Info("register static login required", b.Dir(), b.Endpoint())
				app.Static(b.Dir(), b.Endpoint(), fiber.Static{
					ByteRange: true,
					Next: func(c *fiber.Ctx) bool {
						u, err := getUserFromRequest(c)
						if err != nil {
							return true
						}
						setCorsHeader(c)
						SetContextUser(c, u)
						path, err := url.PathUnescape(c.Path())
						if err != nil {
							return true
						}
						inf, err := vfs.Info(u.Roles, path)
						if err != nil {
							return true
						}
						if inf.Hidden || inf.Type == vfs.ObjectTypeDir {
							return true
						}
						return false
					},
				})
			}
		}
	}
}

func registerHandler(app *fiber.App) {
	app.Options("/*", getCorsOptionHandler())
	app.All("/api/state", handle(stateController.State))
	app.Get("/api/checkupdates", handle(stateController.CheckUpdates))
	app.Post("/api/traceLog", handle(stateController.TraceLog))
	app.Post("/api/user/login", handle(loginController.Login))
	app.Post("/api/store/walk", handleLoginRequired(fileController.Walk))
	app.Post("/api/store/searchPhotos", handleLoginRequired(fileController.SearchPhotos))
	app.Get("/api/store/searchPhotoCount", handleLoginRequired(fileController.SearchPhotoCount))
	app.Post("/api/store/toggleFavorite", handleLoginRequired(fileController.ToggleFavorite))
	app.Post("/api/store/createFolder", handleLoginRequired(fileController.CreateFolder))
	app.Post("/api/store/deleteFiles", handleLoginRequired(fileController.DeleteFiles))
	app.Get("/api/store/fileExists/*", handleLoginRequired(fileController.Exists))
	app.Post("/api/store/fileListExists", handleLoginRequired(fileController.ListExists))
	app.Post("/api/store/upload/*", handleLoginRequired(fileController.Upload))
}

func handleLoginRequired(impl func(c *fiber.Ctx) error) func(c *fiber.Ctx) error {
	return func(c *fiber.Ctx) error {
		defer func() {
			err := recover()
			if err != nil {
				logger.ErrorStacktrace(err, "api_handler_recovered")
				_ = SendError(c, http.StatusInternalServerError, "error")
			}
		}()
		setCorsHeader(c)
		u, err := getUserFromRequest(c)
		if user.IsLoginExpired(err) {
			return SendError(c, http.StatusForbidden, "LOGIN_REQUIRED")
		}
		if err != nil {
			return SendError(c, http.StatusForbidden, err.Error())
		}
		SetContextUser(c, u)
		return impl(c)
	}
}

func handle(impl func(c *fiber.Ctx) error) func(c *fiber.Ctx) error {
	return func(c *fiber.Ctx) error {
		defer func() {
			err := recover()
			if err != nil {
				logger.ErrorStacktrace(err, "api_handler_recovered")
				_ = SendError(c, http.StatusInternalServerError, "error")
			}
		}()
		setCorsHeader(c)
		u, err := getUserFromRequest(c)
		if err == nil && u != nil {
			SetContextUser(c, u)
		}
		return impl(c)
	}
}

func decryptSign(base64Sign string) (string, error) {
	chipertext, err := base64.URLEncoding.DecodeString(base64Sign)
	if err != nil {
		return "", errs.Wrap(err, "base64 decode error")
	}
	origin, err := sign.DecryptToString("sys", chipertext)
	if err != nil {
		return "", errs.Wrap(err, "decrypt error")
	}
	arr := strings.SplitN(origin, " ", 2)
	if len(arr) != 2 {
		return "", errors.New("error sign")
	}
	mills, err := strconv.ParseInt(arr[0], 10, 64)
	if err != nil {
		return "", errors.New("error sign")
	}
	signTime := time.UnixMilli(mills)
	now := time.Now()
	// if now.Sub(signTime) > time.Minute*60 || now.Sub(signTime) < time.Minute*-5 {
	// 	return "", errors.New("error sign time")
	// }
	logger.Info(signTime, now)
	return arr[1], nil
}
