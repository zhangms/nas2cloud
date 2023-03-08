package api

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/gofiber/fiber/v2"
	"nas2cloud/libs/logger"
	"nas2cloud/svc/user"
	"strings"
)

const keyToken = "X-AUTH-TOKEN"
const keyDevice = "X-DEVICE"

func getUserRequestSign(c *fiber.Ctx) (token, device, mode string) {
	signMp := getUserHeaderSign(c)
	if signMp != nil {
		return signMp[keyToken], signMp[keyDevice], "rw"
	}
	signMp = getUserCookieSign(c)
	if signMp != nil {
		return signMp[keyToken], signMp[keyDevice], "rw"
	}
	signMp = getUserQuerySign(c)
	if signMp != nil {
		return signMp[keyToken], signMp[keyDevice], "r"
	}
	return "", "", ""
}

func getUserQuerySign(c *fiber.Ctx) map[string]string {
	var base64sign = c.Query("_sign")
	if len(base64sign) == 0 {
		return nil
	}
	origin, err := decryptSign(base64sign)
	if err != nil {
		logger.Error("sign error:", base64sign)
		return nil
	}
	headers := make(map[string]string)
	err = json.Unmarshal([]byte(origin), &headers)
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
	originToken, err := decryptSign(token)
	if err != nil {
		logger.Error("error sign token", token)
		return nil
	}
	return map[string]string{
		keyToken:  originToken,
		keyDevice: device,
	}
}

func getUserHeaderSign(c *fiber.Ctx) map[string]string {
	token := c.Get(keyToken)
	device := c.Get(keyDevice)
	if len(token) == 0 || len(device) == 0 {
		return nil
	}
	originToken, err := decryptSign(token)
	if err != nil {
		logger.Error("error sign token", token)
		return nil
	}
	return map[string]string{
		keyToken:  originToken,
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
