package es

type SearchResult[T any] struct {
	Took         int64          `json:"took"`
	TimedOut     bool           `json:"timed_out"`
	Shards       Shards         `json:"_shards"`
	Hits         Content[T]     `json:"hits"`
	Aggregations map[string]any `json:"aggregations"`
}

type Shards struct {
	Total      int `json:"total"`
	Successful int `json:"successful"`
	Skipped    int `json:"skipped"`
	Failed     int `json:"failed"`
}

type Content[T any] struct {
	Total    Total     `json:"total"`
	Hits     []*Doc[T] `json:"hits"`
	MaxScore float64   `json:"max_score"`
}

type Total struct {
	Value    int64  `json:"value"`
	Relation string `json:"relation"`
}

type Doc[T any] struct {
	Index  string  `json:"_index"`
	Id     string  `json:"_id"`
	Score  float64 `json:"_score"`
	Source T       `json:"_source"`
	Sort   []any   `json:"sort"`
}
