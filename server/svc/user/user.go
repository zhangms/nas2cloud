package user

import (
	"encoding/json"
	"nas2cloud/libs/logger"
	"nas2cloud/res"
	"strings"
)

type User struct {
	Name     string `json:"name"`
	Password string `json:"password"`
	Roles    string `json:"roles"`
	Mode     string `json:"mode"`
	Avatar   string `json:"avatar"`
}

func (u *User) Clone() *User {
	return &User{
		Name:   u.Name,
		Roles:  u.Roles,
		Mode:   u.Mode,
		Avatar: u.Avatar,
	}
}

func (u *User) WriteMode() bool {
	return strings.Contains(u.Mode, "w")
}

var users = make(map[string]*User)

func DoInit(env string) {
	data, err := res.ReadByEnv(env, "users.json")
	if err != nil {
		logger.ErrorStacktrace(err, "read User conf error")
		return
	}
	list := make([]*User, 0)
	err = json.Unmarshal(data, &list)
	if err != nil {
		logger.ErrorStacktrace(err, "unmarshal User.json error")
		return
	}
	for _, u := range list {
		users[u.Name] = u
	}
}
