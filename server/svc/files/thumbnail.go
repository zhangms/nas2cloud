package files

import (
	"crypto/md5"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"nas2cloud/libs/img"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/res"
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

func startThumbnails() {
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
			".MP3":  &tagThumbnail{defaultThumbnail: "/assets/icon_music.jpg"},
		},
		user:   sysUser,
		queue:  make(chan string, 1024),
		dir:    "/thumb",
		width:  50,
		height: 50,
	}
	processor := res.GetInt("processor.count.filethumb", 1)
	for i := 0; i < processor; i++ {
		logger.Info("thumbnail process started", i)
		go thumbSvc.process()
	}
}

type ThumbnailSvc struct {
	supportType map[string]thumbnail
	queue       chan string
	dir         string
	user        string
	width       int
	height      int
}

func (t *ThumbnailSvc) User() string {
	return t.user
}

func (t *ThumbnailSvc) Dir() string {
	return t.dir
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
			inf.Preview = t.dest(inf.Path)
			t.queue <- inf.Path
		}
	}
}

func (t *ThumbnailSvc) dest(file string) string {
	data := md5.Sum([]byte(file))
	return filepath.Join(t.dir, hex.EncodeToString(data[0:])+".jpg")
}

func (t *ThumbnailSvc) process() {
	for {
		file := <-t.queue
		dest := t.dest(file)
		if vfs.Exists(t.user, dest) {
			continue
		}
		suffix := strings.ToUpper(path.Ext(file))
		thumb := t.supportType[suffix]
		if thumb == nil {
			continue
		}
		err := thumb.exec(t.user, file, dest, t.width, t.height)
		if err != nil {
			logger.Error("image thumb error", reflect.TypeOf(thumb), file, dest, err)
		} else {
			logger.Info("image thumb", file, dest)
		}
	}
}

type thumbnail interface {
	exec(user string, from string, to string, width int, height int) error
}

type imgThumbnail struct {
}

func (i *imgThumbnail) exec(user string, from string, to string, width int, height int) error {
	data, err := vfs.Read(user, from)
	if err != nil {
		return err
	}
	t, err := img.Resize(data, width, height)
	if err != nil {
		return err
	}
	err = vfs.Write(user, to, t)
	if err != nil {
		return err
	}
	return nil
}

type ffmpegThumbnail struct {
}

func (f *ffmpegThumbnail) exec(user string, from string, to string, width int, height int) error {
	err, tryLowPerformance := f.execHighPerformance(user, from, to, width, height)
	if tryLowPerformance {
		logger.Info("ffmpegThumbnail execLowPerformance", from, to)
		return f.execLowPerformance(user, from, to, width, height)
	}
	return err
}

func (f *ffmpegThumbnail) execHighPerformance(user string, from string, to string, width int, height int) (err error, tryLowPerformance bool) {
	storeFrom, fromName, err := vfs.GetStore(user, from)
	if err != nil {
		return err, false
	}
	switch storeFrom.(type) {
	case *vfs.Local:
	default:
		return errors.New("from not support high performance"), true
	}
	storeTo, toName, err := vfs.GetStore(user, to)
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

func (f *ffmpegThumbnail) execLowPerformance(user string, from string, to string, width int, height int) error {
	data, err := vfs.Read(user, from)
	if err != nil {
		return err
	}
	dir := GetTempDir()

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
	err = vfs.Write(user, to, thumbData)
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
	defaultThumbnail string
}

func (t *tagThumbnail) exec(user string, from string, to string, width int, height int) error {
	err := t.execFromTag(user, from, to)
	if err != nil {
		data, err := vfs.Read(user, t.defaultThumbnail)
		if err != nil {
			return err
		}
		err = vfs.Write(user, to, data)
		if err != nil {
			return err
		}
	}
	return nil
}

func (t *tagThumbnail) execFromTag(user string, from string, to string) error {
	reader, err := vfs.Open(user, from)
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
		err = vfs.Write(user, to, pic.Data)
		if err != nil {
			return err
		}
		return nil
	default:
		return errors.New("not support :" + from)
	}
}
