package api

import (
	"encoding/json"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"nas2cloud/env"
	"nas2cloud/libs"
	"nas2cloud/res"
)

type corsConfig struct {
	AllowCredentials bool
	AllowOrigins     string
	AllowHeaders     string
}

var corsConf *corsConfig

func init() {
	if !env.IsActionStart() {
		return
	}
	data, err := res.ReadEnvConfig("cors.json")
	if err != nil {
		panic(err)
	}
	corsConf = &corsConfig{}
	err = json.Unmarshal(data, corsConf)
	if err != nil {
		panic(err)
	}
}

func getCorsOptionHandler() fiber.Handler {
	return cors.New(cors.Config{
		AllowCredentials: corsConf.AllowCredentials,
		AllowOrigins:     corsConf.AllowOrigins,
		AllowHeaders:     corsConf.AllowHeaders,
	})
}

func setCorsHeader(c *fiber.Ctx) {
	c.Set(fiber.HeaderAccessControlAllowCredentials, libs.If(corsConf.AllowCredentials, "true", "false").(string))
	c.Set(fiber.HeaderAccessControlAllowOrigin, corsConf.AllowOrigins)
	c.Set(fiber.HeaderAccessControlAllowHeaders, corsConf.AllowHeaders)
}
