package api

import (
	"context"
	"errors"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/res"
	"nas2cloud/svc/user"
	"net/http"
	"net/url"
	"strings"
)

type Result struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	Data    any    `json:"data"`
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

func SetLoggedUser(c *fiber.Ctx, usr *user.User) {
	ctx := context.WithValue(context.Background(), "loggedUser", usr)
	c.SetUserContext(ctx)
}

func GetLoggedUser(c *fiber.Ctx) (*user.User, error) {
	u := c.UserContext().Value("loggedUser")
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
		if b.MountType() == "local" {
			app.Static(b.Dir(), b.Endpoint(), fiber.Static{
				Next: noStaticPermission,
			})
		}
	}
}

func noStaticPermission(c *fiber.Ctx) bool {
	u, err := getLoginUserFromHeaderOrCookie(c)
	if err != nil {
		return true
	}
	path, err := url.PathUnescape(c.OriginalURL())
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
	return false
}

func registerHandler(app *fiber.App) {
	app.Options("/*", cors.New(cors.Config{
		AllowCredentials: true,
		AllowOrigins:     "*",
		AllowHeaders:     "*",
	}))
	app.Post("/user/login", handler(loginCtrl.Login))
	app.Post("/store/walk", loginRequestHandler(fileWalkCtrl.Walk))
	app.Post("/store/createFolder", loginRequestHandler(fileCreateCtl.CreateFolder))
}

func getLoginUserFromHeaderOrCookie(c *fiber.Ctx) (*user.User, error) {
	token := c.Get("X-AUTH-TOKEN", c.Cookies("X-AUTH-TOKEN", ""))
	device := c.Get("X-DEVICE", c.Cookies("X-DEVICE", ""))
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
	return u, nil
}

func loginRequestHandler(impl func(c *fiber.Ctx) error) func(c *fiber.Ctx) error {
	return func(c *fiber.Ctx) error {
		defer func() {
			err := recover()
			if err != nil {
				logger.ErrorStacktrace(err, "api_handler_recovered")
				_ = SendError(c, http.StatusInternalServerError, "error")
			}
		}()
		c.Set(fiber.HeaderAccessControlAllowCredentials, "true")
		c.Set(fiber.HeaderAccessControlAllowOrigin, "*")
		c.Set(fiber.HeaderAccessControlAllowHeaders, "*")
		u, err := getLoginUserFromHeaderOrCookie(c)
		if err != nil {
			return SendError(c, http.StatusForbidden, "LOGIN_REQUIRED")
		}
		SetLoggedUser(c, u)
		return impl(c)
	}
}

func handler(impl func(c *fiber.Ctx) error) func(c *fiber.Ctx) error {
	return func(c *fiber.Ctx) error {
		defer func() {
			err := recover()
			if err != nil {
				logger.ErrorStacktrace(err, "api_handler_recovered")
				_ = SendError(c, http.StatusInternalServerError, "error")
			}
		}()
		c.Set(fiber.HeaderAccessControlAllowCredentials, "true")
		c.Set(fiber.HeaderAccessControlAllowOrigin, "*")
		c.Set(fiber.HeaderAccessControlAllowHeaders, "*")
		return impl(c)
	}
}
