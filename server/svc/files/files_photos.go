package files

import (
	_ "embed"
	"errors"
	"nas2cloud/libs/vfs"
	"nas2cloud/libs/vfs/vpath"
	"nas2cloud/svc/user"
)

func Photos(username string, searchAfter string) ([]*vfs.ObjectInfo, string, error) {
	role := user.GetUserRoles(username)
	info, _ := vfs.List(role, "/")
	buckets := make([]string, 0)
	for _, inf := range info {
		bucket, _ := vpath.BucketFile(inf.Path)
		buckets = append(buckets, bucket)
	}
	if len(buckets) == 0 {
		return nil, "", errors.New("no buckets")
	}
	return repo.searchPhotos(buckets, searchAfter)
}
