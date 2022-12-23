package external

import (
	"encoding/json"
	"fmt"
	"testing"
)

func TestExternal(t *testing.T) {
	info, _ := Storage.Info("external:/Docs/")
	data, _ := json.Marshal(info)
	fmt.Println(string(data))

}
