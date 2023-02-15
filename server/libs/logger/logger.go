package logger

import (
	"fmt"
	"io"
	"log"
	"os"
	"path"
	"runtime"
	"strings"
)

var inner *log.Logger

const skipCaller = 3

func init() {
	inner = log.New(os.Stdout, "", log.Ldate|log.Ltime|log.Lmicroseconds)
}

func GetWriter() io.Writer {
	return inner.Writer()
}

func Info(v ...any) {
	printInfo(skipCaller, v...)
}

func Warn(v ...any) {
	printWarn(skipCaller, v...)
}

func Error(v ...any) {
	printError(skipCaller, v...)
}

func Fatal(v ...any) {
	inner.Fatal(v...)
}

func PrintIfError(err error, v ...any) {
	if err != nil {
		args := make([]any, 0, len(v)+1)
		args = append(args, err)
		args = append(args, v...)
		printError(skipCaller, args...)
	}
}

func printError(skip int, v ...any) {
	inner.Println(msg("[ERROR] "+caller(skip), v...))
}

func printWarn(skip int, v ...any) {
	inner.Println(msg("[WARN ] "+caller(skip), v...))
}

func printInfo(skip int, v ...any) {
	inner.Println(msg("[INFO ] "+caller(skip), v...))
}

func ErrorStacktrace(v ...any) {
	stack := make([]string, 0)
	for i := 1; ; i++ {
		pc, file, line, ok := runtime.Caller(i)
		if !ok {
			break
		}
		f := runtime.FuncForPC(pc)
		stack = append(stack, fmt.Sprintf("\n    at %s:%s:%d", file, f.Name(), line))
	}
	message := make([]any, 0)
	message = append(message, v...)
	if len(stack) > 0 {
		stack = append(stack, "\n")
		message = append(message, strings.Join(stack, ""))
	}
	printError(skipCaller, message...)
}

func caller(skip int) string {
	_, file, line, ok := runtime.Caller(skip)
	if !ok {
		return ""
	}
	_, shotName := path.Split(file)
	return fmt.Sprintf("%16s:%-4d ", shotName, line)
}

func msg(tag string, v ...any) any {
	ret := tag
	for _, m := range v {
		ret += fmt.Sprintf("|%v", m)
	}
	return ret
}
