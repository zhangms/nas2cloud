package es

type SearchResult[T any] struct {
	Took     int64      `json:"took"`
	TimedOut bool       `json:"timed_out"`
	Hits     Content[T] `json:"hits"`
}

type Content[T any] struct {
	Total Total     `json:"total"`
	Hits  []*Doc[T] `json:"hits"`
	Sort  []any     `json:"sort"`
}

type Total struct {
	Value    int64  `json:"value"`
	Relation string `json:"relation"`
}

type Doc[T any] struct {
	Index  string `json:"_index"`
	Id     string `json:"_id"`
	Source T      `json:"_source"`
}
