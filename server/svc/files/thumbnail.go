package files

import (
	"context"
	"crypto/md5"
	"encoding/hex"
	"errors"
	"fmt"
	"github.com/dhowden/tag"
	"github.com/google/uuid"
	"io"
	"io/fs"
	"nas2cloud/libs/img"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/libs/vfs/vpath"
	"nas2cloud/res"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
)

func startThumbnailExecutor(ctx context.Context) {
	thumbExecutor = &thumbnailExecutor{
		supportType: map[string]thumbnail{
			".JPGX": &imgThumbnail{},
			".JPG":  &ffmpegThumbnail{},
			".JPEG": &ffmpegThumbnail{},
			".PNG":  &ffmpegThumbnail{},
			".GIF":  &ffmpegThumbnail{},
			".BMP":  &ffmpegThumbnail{},
			".MP4":  &ffmpegThumbnail{},
			".MOV":  &ffmpegThumbnail{},
			".MP3":  &tagThumbnail{defaultThumbnail: "/assets/icon_music.jpg"},
		},
		user:   sysUser,
		queue:  make(chan string, 10240),
		bucket: "thumb",
		width:  50,
		height: 50,
	}
	count := res.GetInt("processor.count.file.thumbnail", 1)
	for i := 0; i < count; i++ {
		go thumbExecutor.process(i, ctx)
	}
}

var thumbExecutor *thumbnailExecutor

type thumbnailExecutor struct {
	supportType map[string]thumbnail
	queue       chan string
	bucket      string
	user        string
	width       int
	height      int
}

func (t *thumbnailExecutor) post(obj *vfs.ObjectInfo) {
	t.posts([]*vfs.ObjectInfo{obj})
}

func (t *thumbnailExecutor) posts(infos []*vfs.ObjectInfo) {
	for _, inf := range infos {
		if inf.Hidden || inf.Type != vfs.ObjectTypeFile {
			continue
		}
		if len(inf.Preview) > 0 {
			continue
		}
		suffix := strings.ToUpper(vpath.Ext(inf.Name))
		_, ok := t.supportType[suffix]
		if ok {
			t.queue <- inf.Path
		}
	}
}

func (t *thumbnailExecutor) getThumbDest(file string) string {
	data := md5.Sum([]byte(file))
	thumbName := hex.EncodeToString(data[0:]) + ".jpg"
	return vpath.Join(t.bucket, thumbName)
}

func (t *thumbnailExecutor) process(index int, ctx context.Context) {
	logger.Info("thumbnail process started", index)
	for {
		select {
		case <-ctx.Done():
			logger.Info("thumbnail process stopped", index)
			return
		case path := <-t.queue:
			suffix := strings.ToUpper(vpath.Ext(path))
			thumb := t.supportType[suffix]
			if thumb == nil {
				continue
			}
			dest := t.getThumbDest(path)
			inf, err := repo.get(path)
			if err != nil {
				logger.Error("image thumbExecutor file info get error", err)
				continue
			}
			if inf != nil && inf.Preview == dest {
				continue
			}
			if vfs.Exists(t.user, dest) {
				repo.updatePreview(path, dest)
				continue
			}
			if err := thumb.exec(t.user, path, dest, t.width, t.height); err != nil {
				logger.Error("image thumbExecutor error", reflect.TypeOf(thumb), path, dest, err)
			} else {
				repo.updatePreview(path, dest)
				logger.Info("image thumbExecutor", path, dest)
			}
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

func getAppName() string {
	return "nas2cloud"
}

func getTempDir() string {
	dir := "." + getAppName() + "/temp"
	_ = os.MkdirAll(dir, fs.ModePerm)
	return dir
}

func (f *ffmpegThumbnail) execLowPerformance(user string, from string, to string, width int, height int) error {
	data, err := vfs.Read(user, from)
	if err != nil {
		return err
	}
	dir := getTempDir()

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
