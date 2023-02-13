package storage

import (
	"crypto/md5"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"nas2cloud/conf"
	"nas2cloud/env"
	"nas2cloud/libs/img"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"reflect"
	"strings"

	"github.com/dhowden/tag"
	"github.com/google/uuid"
)

var thumbSvc *ThumbnailSvc

func Thumbnail() *ThumbnailSvc {
	return thumbSvc
}

func init() {
	if !env.IsStarting() {
		return
	}
	thumbSvc = &ThumbnailSvc{
		supportType: map[string]thumbnail{
			".JPGX": &imgThumbnail{},
			".JPG":  &ffmpegThumbnail{},
			".JPEG": &ffmpegThumbnail{},
			".PNG":  &ffmpegThumbnail{},
			".GIF":  &ffmpegThumbnail{},
			".MBP":  &ffmpegThumbnail{},
			".MP4":  &ffmpegThumbnail{},
			".MOV":  &ffmpegThumbnail{},
			".MP3":  &tagThumbnail{thumbUser: "", defaultThumb: "/assets/icon_music.jpg"},
		},
		queue:       make(chan string, 1024),
		thumbDir:    "/thumb",
		thumbWidth:  50,
		thumbHeight: 50,
	}
	processor := conf.GetInt("processor.count.filethumb", 1)
	for i := 0; i < processor; i++ {
		go thumbSvc.process(i)
	}
}

type ThumbnailSvc struct {
	supportType map[string]thumbnail
	queue       chan string
	thumbDir    string
	thumbUser   string
	thumbWidth  int
	thumbHeight int
}

func (t *ThumbnailSvc) ThumbUser() string {
	return t.thumbUser
}

func (t *ThumbnailSvc) ThumbDir() string {
	return t.thumbDir
}

func (t *ThumbnailSvc) Thumbnail(obj *vfs.ObjectInfo) {
	t.BatchThumbnail([]*vfs.ObjectInfo{obj})
}

func (t *ThumbnailSvc) BatchThumbnail(infos []*vfs.ObjectInfo) {
	for _, inf := range infos {
		if inf.Hidden || inf.Type != vfs.ObjectTypeFile {
			continue
		}
		suffix := strings.ToUpper(path.Ext(inf.Name))
		_, ok := t.supportType[suffix]
		if ok {
			inf.Preview = t.getThumbName(inf.Path)
			t.queue <- inf.Path
		}
	}
}

func (t *ThumbnailSvc) getThumbName(file string) string {
	data := md5.Sum([]byte(file))
	return path.Join(t.thumbDir, hex.EncodeToString(data[0:])+".jpg")
}

func (t *ThumbnailSvc) process(index int) {
	logger.Info("start thumbnail process", index)
	for {
		file := <-t.queue
		thumbName := t.getThumbName(file)
		if vfs.Exists(t.thumbUser, thumbName) {
			continue
		}
		suffix := strings.ToUpper(path.Ext(file))
		thumb := t.supportType[suffix]
		if thumb == nil {
			continue
		}
		err := thumb.exec(file, thumbName, t.thumbWidth, t.thumbHeight)
		if err != nil {
			logger.Error("image thumb error", reflect.TypeOf(thumb), file, thumbName, err)
		} else {
			logger.Info("image thumb", file, thumbName)
		}
	}
}

type thumbnail interface {
	exec(from string, to string, width int, height int) error
}

type imgThumbnail struct {
	thumbUser string
}

func (i *imgThumbnail) exec(from string, to string, width int, height int) error {
	data, err := vfs.Read(i.thumbUser, from)
	if err != nil {
		return err
	}
	t, err := img.Resize(data, width, height)
	if err != nil {
		return err
	}
	err = vfs.Write(i.thumbUser, to, t)
	if err != nil {
		return err
	}
	return nil
}

type ffmpegThumbnail struct {
}

func (f *ffmpegThumbnail) exec(from string, to string, width int, height int) error {
	err, tryLowPerformance := f.execHighPerformance(from, to, width, height)
	if tryLowPerformance {
		logger.Info("ffmpegThumbnail execLowPerformance", from, to)
		return f.execLowPerformance(from, to, width, height)
	}
	return err
}

func (f *ffmpegThumbnail) execHighPerformance(from string, to string, width int, height int) (err error, tryLowPerformance bool) {
	storeFrom, fromName, err := vfs.GetStore(sysUser, from)
	if err != nil {
		return err, false
	}
	switch storeFrom.(type) {
	case *vfs.Local:
	default:
		return errors.New("from not support high performance"), true
	}
	storeTo, toName, err := vfs.GetStore(sysUser, to)
	if err != nil {
		return err, false
	}
	switch storeFrom.(type) {
	case *vfs.Local:
	default:
		return errors.New("to not support high performance"), true
	}
	return f.ffmpeg(
		storeFrom.(*vfs.Local).AbsLocal(fromName),
		storeTo.(*vfs.Local).AbsLocal(toName),
		width,
		height), false
}

func (f *ffmpegThumbnail) execLowPerformance(from string, to string, width int, height int) error {
	data, err := vfs.Read(sysUser, from)
	if err != nil {
		return err
	}
	dir := svc.GetTempDir()

	name := uuid.New().String()
	origin := filepath.Join(dir, name+".origin")
	thumb := filepath.Join(dir, name)
	err = os.WriteFile(origin, data, fs.ModePerm)
	if err != nil {
		return err
	}

	err = f.ffmpeg(origin, thumb, width, height)
	if err != nil {
		return err
	}

	thumbData, err := os.ReadFile(thumb)
	if err != nil {
		return err
	}
	err = vfs.Write(sysUser, to, thumbData)
	if err != nil {
		return err
	}
	_ = os.Remove(origin)
	_ = os.Remove(thumb)
	return nil
}

func (f *ffmpegThumbnail) ffmpeg(from string, to string, width int, height int) error {
	//cmd := "ffmpeg -i %s -y -f image2 -t 0.001 -vf scale=%d:%d:force_original_aspect_ratio=increase,crop=%d:%d %s"
	c := exec.Command("ffmpeg", []string{
		"-i", from,
		"-y",
		"-f", "image2",
		"-t", "0.001",
		"-vf", fmt.Sprintf("scale=%d:%d:force_original_aspect_ratio=increase,crop=%d:%d", width, height, width, height),
		to,
	}...)
	err := c.Run()
	if err != nil {
		fmt.Println(c.String())
		return err
	}
	return nil
}

type tagThumbnail struct {
	thumbUser    string
	defaultThumb string
}

func (t *tagThumbnail) exec(from string, to string, width int, height int) error {
	err := t.execFromTag(from, to)
	if err != nil {
		data, err := vfs.Read(t.thumbUser, t.defaultThumb)
		if err != nil {
			return err
		}
		err = vfs.Write(t.thumbUser, to, data)
		if err != nil {
			return err
		}
	}
	return nil
}

func (t *tagThumbnail) execFromTag(from string, to string) error {
	reader, err := vfs.Open(t.thumbUser, from)
	if err != nil {
		return err
	}
	switch r := reader.(type) {
	case io.ReadSeeker:
		meta, err := tag.ReadFrom(r)
		if err != nil {
			return err
		}
		if meta == nil {
			return errors.New("no meta")
		}
		pic := meta.Picture()
		if pic == nil {
			return errors.New("no pic")
		}
		err = vfs.Write(sysUser, to, pic.Data)
		if err != nil {
			return err
		}
		return nil
	default:
		return errors.New("not support :" + from)
	}
}
