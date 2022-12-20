package errs

import "fmt"

type wrap struct {
	message string
	err     any
}

func (w *wrap) Error() string {
	return fmt.Sprintf("%s, caused by:%v ", w.message, w.err)
}

func Wrap(err any, message string) error {
	return &wrap{
		err:     err,
		message: message,
	}
}
