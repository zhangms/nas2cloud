package files

import (
	"nas2cloud/libs/vfs"
	"nas2cloud/svc/es"
)

type repository interface {
	exists(path string) (bool, error)
	get(path string) (*vfs.ObjectInfo, error)
	saveIfAbsent(item *vfs.ObjectInfo) error
	save(item *vfs.ObjectInfo) error
	delete(path string) error
	walk(path string, orderBy string, start int64, stop int64) ([]*vfs.ObjectInfo, int64, error)
	updateSize(file string, size int64) error
	updatePreview(file string, preview string) error
	updateDirModTimeByChildren(path string) error
}

//var repo repository = &repositoryCache{
//	version:     "v1",
//	orderFields: []string{"fileName", "modTime", "creTime", "size"},
//}

var repo repository

func initRepository(env string) {
	es.DoInit(env)
	esRepo := &repositoryEs{
		env: env,
	}
	if err := esRepo.createIndex(); err != nil {
		panic(err)
	}
	repo = esRepo
}
