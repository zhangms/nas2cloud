package thumbs

import (
	"nas2cloud/libs"
	"nas2cloud/libs/img"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
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
	logger.Info("image thumbnail:",
		from, libs.ReadableDataSize(int64(len(data))),
		to, libs.ReadableDataSize(int64(len(t))))
	return nil
}
