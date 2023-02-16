package files

import "nas2cloud/libs/vfs"

type repository interface {
	exists(path string) (bool, error)
	get(path string) (*vfs.ObjectInfo, error)
	saveIfAbsent(item *vfs.ObjectInfo) error
	save(item *vfs.ObjectInfo) error
	delete(path string) error
	find(path string, orderBy string, start int64, stop int64) ([]*vfs.ObjectInfo, int64, error)
	updateSize(userRoles, file string, size int64) error
	updatePreview(file string, preview string)
}

var repo repository = &repositoryCache{
	version:     "v1",
	orderFields: []string{"fileName", "modTime", "creTime", "size"},
}
