package storage

func List(username string, fullPath string) {
	if fullPath == "" || fullPath == "/" {

	}
}

func getUserAuthorizedExternal(username string) []string {
	ret := make([]string, 0)
	for _, e := range externals {
		if e.Authorized(username) {
			ret = append(ret, e.Name)
		}
	}
	return ret
}
