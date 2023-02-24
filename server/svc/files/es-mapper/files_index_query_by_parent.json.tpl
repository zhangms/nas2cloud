{
  "query": {
    "match": {
      "Parent": {
        "query": "{{.Path}}"
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