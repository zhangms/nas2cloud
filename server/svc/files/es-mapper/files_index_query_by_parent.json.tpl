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
    {
      "Type": "asc"
    },
    {
      "{{.OrderByField}}": "{{.OrderByDirect}}"
    }
  ]
}