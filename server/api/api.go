package api

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"nas2cloud/env"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/res"
	"nas2cloud/svc/user"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
)

type Result struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	Data    any    `json:"data"`
}

type apiConfig struct {
	AllowCredentials bool
	AllowOrigins     string
	AllowHeaders     string
}

var config *apiConfig

func init() {
	if !env.IsActionStart() {
		return
	}
	data, err := res.ReadEnvConfig("web.json")
	if err != nil {
		panic(err)
	}
	config = &apiConfig{}
	err = json.Unmarshal(data, config)
	if err != nil {
		panic(err)
	}
}

func ResultError(message string) *Result {
	return &Result{Success: false, Message: message}
}

func ResultOK(data any) *Result {
	return &Result{Success: true, Message: "OK", Data: data}
}

func SendError(c *fiber.Ctx, status int, message string) error {
	return c.Status(status).JSON(ResultError(message))
}

func SendOK(c *fiber.Ctx, data any) error {
	return c.Status(http.StatusOK).JSON(ResultOK(data))
}

func SendErrorPage(c *fiber.Ctx, status int, err error) error {
	c.Type("html", "utf-8")
	data, _ := res.ParseText("err.html", &struct {
		Message string
	}{
		Message: libs.IF(err != nil, func() any {
			return err.Error()
		}, func() any {
			return "some error"
		}).(string),
	})
	return c.Status(status).Send(data)
}

func SendPage(c *fiber.Ctx, data []byte) error {
	c.Type("html", "utf-8")
	return c.Send(data)
}

type ContextKey string

const loginUserKey ContextKey = "loggedUser"

func SetLoggedUser(c *fiber.Ctx, usr *user.User) {
	ctx := context.WithValue(context.Background(), loginUserKey, usr)
	c.SetUserContext(ctx)
}

func GetLoggedUser(c *fiber.Ctx) (*user.User, error) {
	u := c.UserContext().Value(loginUserKey)
	if u == nil {
		return nil, errors.New("NOT_LOGIN")
	}
	return u.(*user.User), nil
}

func Register(app *fiber.App) {
	registerStatic(app)
	registerHandler(app)
}

func registerStatic(app *fiber.App) {
	for _, b := range vfs.GetAllBucket() {
		if b.MountTypeLocal() {
			if b.Authorize() == "PUBLIC" {
				logger.Info("register static public", b.Dir(), b.Endpoint())
				app.Static(b.Dir(), b.Endpoint())
			} else {
				logger.Info("register static login required", b.Dir(), b.Endpoint())
				app.Static(b.Dir(), b.Endpoint(), fiber.Static{
					Next: staticLoginRequired,
				})
			}
		}
	}
}

func staticLoginRequired(c *fiber.Ctx) bool {
	u, err := getLoginUserFromSign(c)
	if err != nil {
		return true
	}
	path, err := url.PathUnescape(c.Path())
	if err != nil {
		return true
	}
	inf, err := vfs.Info(u.Group, path)
	if err != nil {
		return true
	}
	if inf.Hidden || inf.Type == vfs.ObjectTypeDir {
		return true
	}
	setCorsHeader(c)
	return false
}

func registerHandler(app *fiber.App) {
	app.Options("/*", cors.New(cors.Config{
		AllowCredentials: config.AllowCredentials,
		AllowOrigins:     config.AllowOrigins,
		AllowHeaders:     config.AllowHeaders,
	}))
	app.All("/api/state", handle(stateController.State))
	app.Post("/api/user/login", handle(loginController.Login))
	app.Post("/api/store/walk", handleLoginRequired(fileController.Walk))
	app.Post("/api/store/createFolder", handleLoginRequired(fileController.CreateFolder))
	app.Post("/api/store/deleteFiles", handleLoginRequired(fileController.DeleteFiles))
	app.Post("/api/store/upload/*", handleLoginRequired(fileController.Upload))
}

func getRequestSign(c *fiber.Ctx) (token, device, mode string) {
	token = c.Get("X-AUTH-TOKEN", c.Cookies("X-AUTH-TOKEN", ""))
	device = c.Get("X-DEVICE", c.Cookies("X-DEVICE", ""))
	mode = "rw"
	if len(token) > 0 && len(device) > 0 {
		return
	}
	var sign = c.Query("_sign")
	if len(sign) == 0 {
		return
	}
	data, err := base64.URLEncoding.DecodeString(sign)
	if err != nil {
		return
	}
	var decode = string(data)
	arr := strings.SplitN(decode, "|", 2)
	if len(arr) != 2 {
		return
	}
	mills, err := strconv.ParseInt(arr[0], 10, 64)
	if err != nil {
		return
	}
	signTime := time.UnixMilli(mills)
	now := time.Now()
	if now.Sub(signTime) > time.Minute*20 || now.Sub(signTime) < time.Minute*-20 {
		return
	}
	headers := make(map[string]string)
	err = json.Unmarshal([]byte(arr[1]), &headers)
	if err != nil {
		return
	}
	return headers["X-AUTH-TOKEN"], headers["X-DEVICE"], "r"
}

func getLoginUserFromSign(c *fiber.Ctx) (*user.User, error) {
	token, device, mode := getRequestSign(c)
	if len(token) == 0 || len(device) == 0 {
		return nil, errors.New("token not exists")
	}
	arr := strings.SplitN(token, "-", 2)
	if len(arr) != 2 {
		return nil, errors.New("token error")
	}
	u := user.GetLoggedUser(arr[0], device, arr[1])
	if u == nil {
		return nil, errors.New("login expired")
	}
	u.Mode = mode
	return u, nil
}

func setCorsHeader(c *fiber.Ctx) {
	c.Set(fiber.HeaderAccessControlAllowCredentials, libs.If(config.AllowCredentials, "true", "false").(string))
	c.Set(fiber.HeaderAccessControlAllowOrigin, config.AllowOrigins)
	c.Set(fiber.HeaderAccessControlAllowHeaders, config.AllowHeaders)
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
		u, err := getLoginUserFromSign(c)
		if err != nil {
			return SendError(c, http.StatusForbidden, "LOGIN_REQUIRED")
		}
		SetLoggedUser(c, u)
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
		u, err := getLoginUserFromSign(c)
		if err == nil && u != nil {
			SetLoggedUser(c, u)
		}
		return impl(c)
	}
}
