package files

import "testing"

func TestPhotoSearch(t *testing.T) {

	initRepository("dev")
	ps := &photoSearch{}

	ps.search()
}
