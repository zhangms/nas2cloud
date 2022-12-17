package user

import (
	"encoding/json"
	"nas2cloud/libs/logger"
	"nas2cloud/resources"
)

var users = make(map[string]*user)

func init() {
	data, err := resources.ReadData("users.json")
	if err != nil {
		logger.ErrorStacktrace(err, "read user config error")
		return
	}

	list := make([]*user, 0)
	err = json.Unmarshal(data, &list)
	if err != nil {
		logger.ErrorStacktrace(err, "unmarshal user.json error")
		return
	}
	for _, u := range list {
		users[u.Name] = u
	}
}

func getUserByName(name string) *user {
	return users[name]
}
