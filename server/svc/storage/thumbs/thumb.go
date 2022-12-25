package thumbs

import (
	"errors"
	"fmt"
	"github.com/google/uuid"
	"io/fs"
	"nas2cloud/libs/img"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/svc"
	"os"
	"os/exec"
	"path"
)

type thumbnail interface {
	exec(from string, to string, width int, height int) error
}

type imgThumbnail struct {
}

func (i *imgThumbnail) exec(from string, to string, width int, height int) error {
	data, err := vfs.Read(ThumbUser, from)
	if err != nil {
		return err
	}
	t, err := img.Resize(data, width, height)
	if err != nil {
		return err
	}
	err = vfs.Write(ThumbUser, to, t)
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
	storeFrom, fromName, err := vfs.GetStore(ThumbUser, from)
	if err != nil {
		return err, false
	}
	switch storeFrom.(type) {
	case *vfs.Local:
	default:
		return errors.New("from not support high performance"), true
	}
	storeTo, toName, err := vfs.GetStore(ThumbUser, to)
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
	data, err := vfs.Read(ThumbUser, from)
	if err != nil {
		return err
	}
	dir := svc.GetTempDir()

	name := uuid.New().String()
	origin := path.Join(dir, name+".origin")
	thumb := path.Join(dir, name)
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
	err = vfs.Write(ThumbUser, to, thumbData)
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
