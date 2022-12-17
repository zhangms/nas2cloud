package user

import "errors"

func Login(name string, password string) (string, error) {
	usr := getUserByName(name)
	if usr == nil || usr.Password != password {
		return "", errors.New("username or password error")
	}
	return "hello", nil
}
