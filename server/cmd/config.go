package cmd

import (
	"errors"
	"fmt"
	"github.com/urfave/cli/v2"
	"io/fs"
	"nas2cloud/libs"
	"nas2cloud/libs/errs"
	"os"
	"path/filepath"
	"strings"
)

var defaultConfigFlags = startFlags{
	profile: "dev",
}

var configFlagProfile = &cli.StringFlag{
	Name:        "profile",
	Usage:       "environment profile name",
	DefaultText: fmt.Sprintf("%s", defaultConfigFlags.profile),
}

var configCommand = &cli.Command{
	Name:   "config",
	Usage:  "generate server config",
	Action: genConfig,
	Flags: []cli.Flag{
		configFlagProfile,
	},
}

func genConfig(context *cli.Context) error {
	profileName := defaultConfigFlags.profile
	if context.IsSet(configFlagProfile.Name) {
		profileName = context.String(configFlagProfile.Name)
	}
	dir := libs.Resource(profileName)
	_, err := os.Stat(dir)
	if !os.IsNotExist(err) {
		return errors.New(fmt.Sprintf("config dir: %s is already exists", dir))
	}
	if err = os.Mkdir(dir, fs.ModePerm); err != nil {
		return errs.Wrap(err, "config dir create error : "+dir)
	}
	if err = genUserConfig(dir); err != nil {
		return errs.Wrap(err, "gen user.json error")
	}
	if err = genRedis(dir); err != nil {
		return errs.Wrap(err, "gen redis.json error")
	}
	if err = genEs(dir); err != nil {
		return errs.Wrap(err, "gen es.json error")
	}
	if err = genCors(dir); err != nil {
		return errs.Wrap(err, "gen cors.json error")
	}
	if err = genGlobalConfig(dir); err != nil {
		return errs.Wrap(err, "gen config.json error")
	}
	if err = genBucket(dir); err != nil {
		return errs.Wrap(err, "gen bucket.json error")
	}
	return nil
}

func genBucket(dir string) error {
	tpl := `
[
  {
    "id": "client",
    "name": "client",
    "mountType": "local",
    "endpoint": "client",
    "authorize": "PUBLIC",
    "mode": "rw",
    "hidden": true,
    "comment":"客户端更新目录"
  },
  {
    "id": "app",
    "name": "app",
    "mountType": "local",
    "endpoint": "app",
    "authorize": "PUBLIC",
    "mode": "rw",
    "hidden": true,
    "comment":"WEB版客户端目录"
  },
  {
    "id": "assets",
    "name": "thumb",
    "mountType": "local",
    "endpoint": "assets",
    "authorize": "ALL",
    "mode": "rw",
    "hidden": true,
    "comment":"公共资源目录,包括用户头像之类的"
  },
  {
    "id": "thumb",
    "name": "thumb",
    "mountType": "local",
    "endpoint": "thumb",
    "authorize": "ALL",
    "mode": "rw",
    "hidden": true,
    "comment":"照片缩略图生成目录"
  },
  {
    "id": "Movies",
    "name": "Movies",
    "mountType": "local",
    "endpoint": "/path/to/Movies",
    "authorize": "admin,family",
    "mode": "rw",
    "hidden": false,
    "comment":"自定义的共享目录"
  },
  {
    "id": "userhome_user",
    "name": "USER的文件夹",
    "mountType": "local",
    "endpoint": "/path/to/NAS/Users/username",
    "authorize": "username",
    "mode": "rw",
    "hidden": false,
    "comment":"自定义的用户目录"
  }
]
`
	return os.WriteFile(filepath.Join(dir, "bucket.json"), []byte(strings.TrimSpace(tpl)), fs.ModePerm)
}

func genGlobalConfig(dir string) error {
	tpl := `
{
  "app.name": "Nas2cloud",
  "processor.count.file.event": "1",
  "processor.count.file.thumbnail": "1"
}
`
	return os.WriteFile(filepath.Join(dir, "conf.json"), []byte(strings.TrimSpace(tpl)), fs.ModePerm)
}

func genCors(dir string) error {
	tpl := `
{
  "AllowCredentials": true,
  "AllowOrigins": "http://localhost:3000",
  "AllowHeaders": "x-requested-with,content-type,X-AUTH-TOKEN,X-DEVICE"
}
`
	return os.WriteFile(filepath.Join(dir, "cors.json"), []byte(strings.TrimSpace(tpl)), fs.ModePerm)
}

func genEs(dir string) error {
	tpl := `
{
  "address": [
    "http://127.0.0.1:9200"
  ]
}
`
	return os.WriteFile(filepath.Join(dir, "es.json"), []byte(strings.TrimSpace(tpl)), fs.ModePerm)
}

func genRedis(dir string) error {
	tpl := `
{
  "Addr": "127.0.0.1:6379",
  "Password": "",
  "DB": 0
}
`
	return os.WriteFile(filepath.Join(dir, "redis.json"), []byte(strings.TrimSpace(tpl)), fs.ModePerm)
}

func genUserConfig(dir string) error {
	tpl := `
[
  {
    "name": "admin",
    "password": "admin",
    "roles": "admin",
    "avatar": "/assets/avatar_admin.jpg",
    "mode": "rw"
  },
  {
    "name": "username",
    "password": "password",
    "roles": "username,family",
    "avatar": "/assets/avatar_username.jpg",
    "avatarLarge": "/assets/avatar_username_large.jpg",
    "mode": "rw"
  }
]
`
	return os.WriteFile(filepath.Join(dir, "users.json"), []byte(strings.TrimSpace(tpl)), fs.ModePerm)
}
