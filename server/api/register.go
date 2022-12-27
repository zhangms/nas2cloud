package api

import (
	"errors"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"nas2cloud/api/base"
	"nas2cloud/api/store"
	"nas2cloud/api/usr"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc/storage/thumbs"
	"nas2cloud/svc/user"
	"net/http"
	"strings"
)

func Register(app *fiber.App) {
	bucket, _, _ := vfs.GetBucket(thumbs.ThumbUser, thumbs.ThumbnailDir)
	app.Static(thumbs.ThumbnailDir, bucket.Endpoint())
	app.Options("/*", cors.New(cors.Config{
		AllowCredentials: true,
		AllowOrigins:     "*",
		AllowHeaders:     "*",
	}))
	app.Get("/page/store/nav", loginHandler(store.NavigatePage))
	app.Post("/store/nav", loginHandler(store.Navigate))
	app.Post("/user/login", handler(usr.Login))
}

func getLoggedUser(c *fiber.Ctx) (*user.User, error) {
	token := c.Get("X-AUTH-TOKEN")
	device := c.Get("device")
	if len(token) == 0 || len(device) == 0 {
		return nil, errors.New("token not exists")
	}
	arr := strings.SplitN(token, " ", 2)
	if len(arr) != 2 {
		return nil, errors.New("token error")
	}
	u := user.GetLoggedUser(arr[0], device, arr[1])
	if u == nil {
		return nil, errors.New("login expired")
	}
	return u, nil
}

func loginHandler(impl func(c *fiber.Ctx) error) func(c *fiber.Ctx) error {
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
			return base.SendLoginRequired(c)
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
