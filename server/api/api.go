package api

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"nas2cloud/env"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/res"
	"nas2cloud/svc/sign"
	"nas2cloud/svc/user"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	fiberLogger "github.com/gofiber/fiber/v2/middleware/logger"
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

func SendMsg(c *fiber.Ctx, message string) error {
	return c.Status(http.StatusOK).JSON(&Result{Success: true, Message: message})
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

func SetContextUser(c *fiber.Ctx, usr *user.User) {
	ctx := context.WithValue(context.Background(), loginUserKey, usr)
	c.SetUserContext(ctx)
}

func GetContextUser(c *fiber.Ctx) (*user.User, error) {
	u := c.UserContext().Value(loginUserKey)
	if u == nil {
		return nil, errors.New("NOT_LOGIN")
	}
	return u.(*user.User), nil
}

func Register(app *fiber.App) {
	initLooger(app)
	registerStatic(app)
	registerHandler(app)
}

func initLooger(app *fiber.App) {
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
				app.Static(b.Dir(), b.Endpoint(), fiber.Static{
					ByteRange: true,
				})
			} else {
				logger.Info("register static login required", b.Dir(), b.Endpoint())
				app.Static(b.Dir(), b.Endpoint(), fiber.Static{
					Next:      staticLoginRequired,
					ByteRange: true,
				})
			}
		}
	}
}

func staticLoginRequired(c *fiber.Ctx) bool {
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
}

func registerHandler(app *fiber.App) {
	app.Options("/*", cors.New(cors.Config{
		AllowCredentials: config.AllowCredentials,
		AllowOrigins:     config.AllowOrigins,
		AllowHeaders:     config.AllowHeaders,
	}))
	app.All("/api/state", handle(stateController.State))
	app.Get("/api/checkupdates", handle(stateController.CheckUpdates))
	app.Post("/api/user/login", handle(loginController.Login))
	app.Post("/api/store/walk", handleLoginRequired(fileController.Walk))
	app.Post("/api/store/createFolder", handleLoginRequired(fileController.CreateFolder))
	app.Post("/api/store/deleteFiles", handleLoginRequired(fileController.DeleteFiles))
	app.Get("/api/store/fileExists/*", handleLoginRequired(fileController.Exists))
	app.Post("/api/store/fileListExists", handleLoginRequired(fileController.ListExists))
	app.Post("/api/store/upload/*", handleLoginRequired(fileController.Upload))
}

const keyToken = "X-AUTH-TOKEN"
const keyDevice = "X-DEVICE"

func getRequestSign(c *fiber.Ctx) (token, device, mode string) {
	sign := getHeaderSign(c)
	if sign != nil {
		return sign[keyToken], sign[keyDevice], "rw"
	}
	sign = getCookieSign(c)
	if sign != nil {
		return sign[keyToken], sign[keyDevice], "rw"
	}
	sign = getQuerySign(c)
	if sign != nil {
		return sign[keyToken], sign[keyDevice], "r"
	}
	return "", "", ""
}

func getQuerySign(c *fiber.Ctx) map[string]string {
	var base64sign = c.Query("_sign")
	if len(base64sign) == 0 {
		return nil
	}
	chipertext, err := base64.URLEncoding.DecodeString(base64sign)
	if err != nil {
		return nil
	}
	origin, err := sign.Sign().DecryptToString("sys", chipertext)
	if err != nil {
		logger.Error("sign error:", base64sign)
		return nil
	}
	arr := strings.SplitN(origin, " ", 2)
	if len(arr) != 2 {
		return nil
	}
	mills, err := strconv.ParseInt(arr[0], 10, 64)
	if err != nil {
		return nil
	}
	signTime := time.UnixMilli(mills)
	now := time.Now()
	if now.Sub(signTime) > time.Minute*60 || now.Sub(signTime) < time.Minute*-5 {
		return nil
	}
	headers := make(map[string]string)
	err = json.Unmarshal([]byte(arr[1]), &headers)
	if err != nil {
		return nil
	}
	return headers
}

func getCookieSign(c *fiber.Ctx) map[string]string {
	token := c.Cookies(keyToken)
	device := c.Cookies(keyDevice)
	if len(token) == 0 || len(device) == 0 {
		return nil
	}
	return map[string]string{
		keyToken:  token,
		keyDevice: device,
	}
}

func getHeaderSign(c *fiber.Ctx) map[string]string {
	token := c.Get(keyToken)
	device := c.Get(keyDevice)
	if len(token) == 0 || len(device) == 0 {
		return nil
	}
	return map[string]string{
		keyToken:  token,
		keyDevice: device,
	}
}

func getUserFromRequest(c *fiber.Ctx) (*user.User, error) {
	token, device, mode := getRequestSign(c)
	if len(token) == 0 || len(device) == 0 {
		return nil, errors.New("sign error")
	}
	arr := strings.SplitN(token, "-", 2)
	if len(arr) != 2 {
		return nil, errors.New("token error")
	}
	u, err := user.FindUserByAuthToken(arr[0], arr[1], device)
	if err != nil {
		return nil, err
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
