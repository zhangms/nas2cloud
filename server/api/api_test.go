package api

import (
	"fmt"
	"testing"
	"time"
)

func TestX(t *testing.T) {
	mills := int64(1674155648739)
	signTime := time.UnixMilli(mills)
	now := time.Now()

	fmt.Println(signTime.Sub(now), "|", now.Sub(signTime))

	fmt.Println(signTime.Before(now), "|", signTime.After(now))

}
