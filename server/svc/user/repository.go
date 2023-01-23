package user

import (
	"encoding/json"
	"errors"
	"nas2cloud/libs/logger"
	"nas2cloud/res"
	"nas2cloud/svc/cache"
	"strings"
)

var users = make(map[string]*User)

func init() {
	data, err := res.ReadEnvConfig("users.json")
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

func findUser(name string, password string) *User {
	usr := users[name]
	if usr == nil || usr.Password != password {
		return nil
	}
	return usr
}

func findUserByName(name string) *User {
	return users[name]
}

func deviceType(device string) string {
	arr := strings.Split(strings.ToLower(device), ",")
	devType := arr[0]
	if strings.Contains(devType, "android") || strings.Contains(devType, "ios") {
		devType = "mobile"
	}
	return devType
}

func keyToken(username string, device string) string {
	return cache.Join(username, "v1", "userLoginToken", deviceType(device))
}

func expireUserAuthToken(username string, device string) error {
	key := keyToken(username, device)
	_, err := cache.Del(key)
	return err

	//sqlDb := db.DB()
	//result, err := sqlDb.Exec("update user_auth_token set status=0, git_modified=now()"+
	//	" where user_name=? and device_type=? and status=1",
	//	username, deviceType(device))
	//if err != nil {
	//	return 0, err
	//}
	//return result.RowsAffected()
}

func createNewUserAuthToken(userName string, token string, device string) error {
	key := keyToken(userName, device)
	_, err := cache.Set(key, token)
	return err
	//sqlDb := db.DB()
	//result, err := sqlDb.Exec("insert into user_auth_token"+
	//	"(gmt_create, git_modified, user_name, token, device_type, device, status)"+
	//	" values (now(), now(), ?, ?, ?, ?, ?)",
	//	userName, token, deviceType(device), device, 1)
	//if err != nil {
	//	return -1, err
	//}
	//return result.LastInsertId()
}

func findUserByAuthToken(userName string, device string, token string) (*User, error) {
	key := keyToken(userName, device)
	value, err := cache.Get(key)
	if err != nil {
		return nil, err
	}
	if value != token {
		return nil, errors.New("user not login")
	}
	usr := findUserByName(userName)
	if usr == nil {
		return nil, errors.New("user not exists")
	}
	return usr.Clone(), nil

	//sqlDb := db.DB()
	//row := sqlDb.QueryRow("select count(1) from user_auth_token"+
	//	" where token=? and user_name=? and status=1 and device_type=?",
	//	token, userName, deviceType(device))
	//var count int
	//err := row.Scan(&count)
	//if err != nil {
	//	return nil, err
	//}
	//if count == 0 {
	//	return nil, nil
	//}
	//usr := findUserByName(userName)
	//if usr == nil {
	//	return nil, errors.New("user not exists")
	//}
	//return usr.Clone(), nil
}

func GetUserRoles(userName string) string {
	usr := users[userName]
	if usr != nil {
		return usr.Roles
	}
	return ""
}
