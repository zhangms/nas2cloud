package user

import "strings"

type User struct {
	Name     string `json:"name"`
	Password string `json:"password"`
	Group    string `json:"group"`
	Mode     string `json:"mode"`
	Avatar   string `json:"avatar"`
}

func (u *User) Clone() *User {
	return &User{
		Name:   u.Name,
		Group:  u.Group,
		Mode:   u.Mode,
		Avatar: u.Avatar,
	}
}

func (u *User) WriteMode() bool {
	return strings.Contains(u.Mode, "w")
}
