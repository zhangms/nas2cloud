package logger

import (
	"errors"
	"testing"
)

func TestLogger(t *testing.T) {

	err := errors.New("error")

	Info("hello", "world")
	Error("hello", "world")
	ErrorStacktrace(err, "hello", "world")

}
