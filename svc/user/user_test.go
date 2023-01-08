package user

import (
	"fmt"
	"testing"
	"time"
)

func TestGetUser(t *testing.T) {
	findUser("zms", "123")
	fmt.Println(time.Now())
}
