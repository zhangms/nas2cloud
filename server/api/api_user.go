package api

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"github.com/gofiber/fiber/v2"
	"nas2cloud/libs/logger"
	"nas2cloud/svc/sign"
	"nas2cloud/svc/user"
	"strconv"
	"strings"
	"time"
)

const keyToken = "X-AUTH-TOKEN"
const keyDevice = "X-DEVICE"

func getUserRequestSign(c *fiber.Ctx) (token, device, mode string) {
	sign := getUserHeaderSign(c)
	if sign != nil {
		return sign[keyToken], sign[keyDevice], "rw"
	}
	sign = getUserCookieSign(c)
	if sign != nil {
		return sign[keyToken], sign[keyDevice], "rw"
	}
	sign = getUserQuerySign(c)
	if sign != nil {
		return sign[keyToken], sign[keyDevice], "r"
	}
	return "", "", ""
}

func getUserQuerySign(c *fiber.Ctx) map[string]string {
	var base64sign = c.Query("_sign")
	if len(base64sign) == 0 {
		return nil
	}
	chipertext, err := base64.URLEncoding.DecodeString(base64sign)
	if err != nil {
		return nil
	}
	origin, err := sign.Instance().DecryptToString("sys", chipertext)
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

func getUserCookieSign(c *fiber.Ctx) map[string]string {
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

func getUserHeaderSign(c *fiber.Ctx) map[string]string {
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
	token, device, mode := getUserRequestSign(c)
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
