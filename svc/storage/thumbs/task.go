package thumbs

import (
	"crypto/md5"
	"encoding/hex"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"path"
	"reflect"
	"strings"
)

const ThumbnailDir = "/__thumb__"
const ThumbUser = "root"

const thumbWidth = 100
const thumbHeight = 100

var queue chan string

func init() {
	queue = make(chan string, 10240)
	for i := 0; i < 20; i++ {
		go worker()
	}
}

var supportType = map[string]thumbnail{
	".JPG":  &ffmpegThumbnail{},
	".JPEG": &ffmpegThumbnail{},
	".PNG":  &ffmpegThumbnail{},
	".GIF":  &ffmpegThumbnail{},
	".MP4":  &ffmpegThumbnail{},
	".MOV":  &ffmpegThumbnail{},
}

func worker() {
	for true {
		file := <-queue
		thumbName := getThumbName(file)
		if vfs.Exists(ThumbUser, thumbName) {
			continue
		}
		suffix := strings.ToUpper(path.Ext(file))
		thumb := supportType[suffix]
		if thumb == nil {
			continue
		}
		err := thumb.exec(file, thumbName, thumbWidth, thumbHeight)
		if err != nil {
			logger.Error("image thumb error", reflect.TypeOf(thumb), file, err)
		} else {
			logger.Info("image thumb", file)
		}
	}
}

func Thumbnail(obj *vfs.ObjectInfo) {
	BatchThumbnail([]*vfs.ObjectInfo{obj})
}

func BatchThumbnail(infos []*vfs.ObjectInfo) {
	for _, inf := range infos {
		if inf.Hidden || inf.Type != vfs.ObjectTypeFile {
			continue
		}
		inf.Preview = getThumbName(inf.Path)
		suffix := strings.ToUpper(path.Ext(inf.Name))
		_, ok := supportType[suffix]
		if ok {
			queue <- inf.Path
		}
	}
}

func getThumbName(file string) string {
	data := md5.Sum([]byte(file))
	return path.Join(ThumbnailDir, hex.EncodeToString(data[0:])+".jpg")
}
