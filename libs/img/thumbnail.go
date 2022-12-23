package img

import (
	"bytes"
	"github.com/fogleman/gg"
	"image"
	_ "image/gif"
	"image/jpeg"
	_ "image/jpeg"
	_ "image/png"
	"math"
)

func Thumbnail(imgData []byte, width int, height int) ([]byte, error) {
	reader := bytes.NewReader(imgData)
	im, _, err := image.Decode(reader)
	if err != nil {
		return nil, err
	}
	tw, th := float64(width), float64(height)
	bw := float64(im.Bounds().Dx())
	bh := float64(im.Bounds().Dy())
	sx := tw / bw
	sy := th / bh
	ms := math.Max(sx, sy)
	ax := (tw - bw*ms) / 2
	ay := (th - bh*ms) / 2
	if math.Abs(ax) < 10 {
		ax = 0
	}
	if math.Abs(ay) < 10 {
		ay = 0
	}
	dc := gg.NewContext(int(tw), int(th))
	dc.Push()
	dc.ScaleAbout(ms, ms, ax, ay)
	dc.DrawImage(im, 0, 0)
	dc.Pop()
	ret := dc.Image()
	var buffer bytes.Buffer
	err = jpeg.Encode(&buffer, ret, &jpeg.Options{
		Quality: 100,
	})
	if err != nil {
		return nil, err
	}
	return buffer.Bytes(), nil
}
