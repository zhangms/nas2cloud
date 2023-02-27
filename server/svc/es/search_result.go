package es

import "encoding/json"

type SearchResult[T any] struct {
	Took         int64      `json:"took"`
	TimedOut     bool       `json:"timed_out"`
	Shards       Shards     `json:"_shards"`
	Hits         Content[T] `json:"hits"`
	Aggregations any        `json:"aggregations"`
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

type AggsBucket struct {
	KeyAsString string `json:"key_as_string"`
	Key         any    `json:"key"`
	DocCount    int    `json:"doc_count"`
}

func GetAggsBuckets(aggs any, aggsName string) ([]*AggsBucket, error) {
	data, err := json.Marshal(aggs)
	if err != nil {
		return nil, err
	}
	ret := make(map[string]map[string][]*AggsBucket)
	if err = json.Unmarshal(data, &ret); err != nil {
		return nil, err
	}
	return ret[aggsName]["buckets"], nil
}
