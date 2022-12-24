package api

import (
	"github.com/gofiber/fiber/v2"
	"nas2cloud/api/base"
	"nas2cloud/api/store"
	"nas2cloud/api/user"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc/storage/thumbs"
	"net/http"
)

func Register(app *fiber.App) {
	bucket, _, _ := vfs.GetBucket(thumbs.ThumbUser, thumbs.ThumbnailDir)
	app.Static(thumbs.ThumbnailDir, bucket.Endpoint())
	app.Get("/store/nav", handler(store.Navigate))
	app.Get("/page/store/nav", handler(store.NavigatePage))
	app.Post("/user/login", handler(user.Login))
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
		return impl(c)
	}
}
