package user

import (
	"errors"
	"github.com/google/uuid"
	"nas2cloud/libs/logger"
)

func Login(name string, password string, device string) (string, error) {
	usr := findUser(name, password)
	if usr == nil {
		return "", errors.New("username or password error")
	}
	_, err := expireUserAuthToken(usr.Name, device)
	if err != nil {
		logger.ErrorStacktrace(err)
		return "", errors.New("login failed")
	}
	token := uuid.New().String()
	tokenId, err := createNewUserAuthToken(usr.Name, token, device)
	if err != nil {
		logger.ErrorStacktrace(err)
		return "", errors.New("login failed")
	}
	logger.Info("LOGIN_SUCCESS", name, device, tokenId)
	return token, nil
}

func GetLoggedUser(name string, device string, token string) *User {
	usr, err := findUserByAuthToken(name, device, token)
	if err != nil {
		logger.ErrorStacktrace(err)
		return nil
	}
	return usr
}
