{
  "query": {
    "constant_score":{
      "filter": {
        "term": {"Parent": "{{.Path}}"}
      }
    }
  },
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