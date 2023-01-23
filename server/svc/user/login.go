package user

import (
	"errors"
	"nas2cloud/libs/logger"

	"github.com/google/uuid"
)

func Login(name string, password string, device string) (string, error) {
	usr := findUser(name, password)
	if usr == nil {
		return "", errors.New("username or password error")
	}
	err := expireUserAuthToken(usr.Name, device)
	if err != nil {
		logger.ErrorStacktrace(err)
		return "", errors.New("login failed")
	}
	token := uuid.New().String()
	err = createNewUserAuthToken(usr.Name, token, device)
	if err != nil {
		logger.ErrorStacktrace(err)
		return "", errors.New("login failed")
	}
	logger.Info("LOGIN_SUCCESS", name, device)
	return token, nil
}

func GetLoggedUser(name string, device string, token string) *User {
	usr, err := findUserByAuthToken(name, device, token)
	if err != nil {
		logger.Error(name, device, token, err)
		return nil
	}
	return usr
}

func GetUserByName(name string) *User {
	return findUserByName(name)
}