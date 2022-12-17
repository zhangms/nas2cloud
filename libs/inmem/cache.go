package inmem

import "sync"

type entry struct {
}

type Cache struct {
	mp *sync.Map
}
