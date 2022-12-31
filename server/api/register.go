package api

import (
	"errors"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"nas2cloud/api/base"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc/user"
	"net/http"
	"strings"
)

func Register(app *fiber.App) {
	registerStatic(app)
	registerHandler(app)
}

func registerStatic(app *fiber.App) {
	root := "root"
	infos, _ := vfs.List(root, "/")
	for _, info := range infos {
		b, _, _ := vfs.GetBucket(root, info.Path)
		if b.MountType() == "local" {
			app.Static(b.Dir(), b.Endpoint(), fiber.Static{
				Next: noStaticPermission,
			})
		}
	}
}

func noStaticPermission(c *fiber.Ctx) bool {
	u, err := getLoggedUser(c)
	if err != nil {
		return true
	}
	inf, err := vfs.Info(u.Group, c.OriginalURL())
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
	app.Post("/store/walk", loginRequestHandler(fileWalkCtrl.Walk))
	app.Post("/user/login", handler(loginCtrl.Login))
}

func getLoggedUser(c *fiber.Ctx) (*user.User, error) {
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
				_ = base.SendError(c, http.StatusInternalServerError, "error")
			}
		}()
		c.Set(fiber.HeaderAccessControlAllowCredentials, "true")
		c.Set(fiber.HeaderAccessControlAllowOrigin, "*")
		c.Set(fiber.HeaderAccessControlAllowHeaders, "*")
		u, err := getLoggedUser(c)
		if err != nil {
			return base.SendError(c, http.StatusForbidden, "LOGIN_REQUIRED")
		}
		base.SetLoggedUser(c, u)
		return impl(c)
	}
}

func handler(impl func(c *fiber.Ctx) error) func(c *fiber.Ctx) error {
	return func(c *fiber.Ctx) error {
		defer func() {
			err := recover()
			if err != nil {
				logger.ErrorStacktrace(err, "api_handler_recovered")
				_ = base.SendError(c, http.StatusInternalServerError, "error")
			}
		}()
		c.Set(fiber.HeaderAccessControlAllowCredentials, "true")
		c.Set(fiber.HeaderAccessControlAllowOrigin, "*")
		c.Set(fiber.HeaderAccessControlAllowHeaders, "*")
		return impl(c)
	}
}
