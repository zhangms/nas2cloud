package files

import (
	_ "embed"
	"errors"
	"nas2cloud/libs/vfs"
	"nas2cloud/libs/vfs/vpath"
	"nas2cloud/svc/user"
)

func SearchPhotoByTime(username string, groupTime string, searchAfter string) ([]*vfs.ObjectInfo, string, error) {
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
	return repo.searchPhotos(buckets, groupTime, searchAfter)
}

func SearchPhotoCountByTime(username string) ([]*KeyValue, error) {
	role := user.GetUserRoles(username)
	info, _ := vfs.List(role, "/")
	buckets := make([]string, 0)
	for _, inf := range info {
		bucket, _ := vpath.BucketFile(inf.Path)
		buckets = append(buckets, bucket)
	}
	if len(buckets) == 0 {
		return nil, errors.New("no buckets")
	}
	return repo.searchPhotosGroupTimeCount(buckets)
}
