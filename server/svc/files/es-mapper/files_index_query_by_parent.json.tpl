{
  "query": {
    "constant_score":{
      "filter": {
        "term": {"Parent": "{{.Path}}"}
      }
    }
  },
  "track_total_hits": true,
  "from": {{.From}},
  "size": {{.Size}},
  "sort": [
    {{if eq .OrderByField "Name"}}
    {
      "Type": "asc"
    },
    {{end}}
    {
      "{{.OrderByField}}": "{{.OrderByDirect}}"
    }
  ]
}