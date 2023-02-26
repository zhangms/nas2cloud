{
  "query": {
    "bool": {
      "filter": [
        {
          "term": {
            "Type": "FILE"
          }
        },
        {
          "terms": {
            "Bucket": [
            {{range .Buckets}}"{{.}}",{{end}}
            "_NO_BUCKET_"
            ]
          }
        },
        {
          "terms": {
            "Ext": [
              ".JPG",
              ".PNG",
              ".JPEG",
              ".BMP",
              ".GIF",
              ".MP4",
              ".MOV",
              ".MKV",
              ".3GP"
            ]
          }
        }
      ],
      "must_not": [
        {
          "terms": {
            "Parent": [
              "/Family/PHOTO/nas2cloud-pmz/Pictures/Gallery/owner/便便"
            ]
          }
        }
      ]
    }
  },
  "size": 256,
  {{if .SearchAfter}}
  "search_after": {{.SearchAfter}},
  {{end}}
  "sort": [
    {
      "ModTime": "desc"
    },
    {
      "Path": "desc"
    }
  ]
}