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
        {{if .ModTimeRange}}
        {
          "range": {
            "ModTime": {
              "gte": "{{.ModTimeRange.StartTime}}",
              "lt": "{{.ModTimeRange.EndTime}}",
              "format": "{{.ModTimeRange.Format}}",
              "time_zone": "+08:00"
            }
          }
        },
        {{end}}
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
  "track_total_hits": true,
  "size": {{.Size}},
  {{if .SearchAfter}}
  "search_after": {{.SearchAfter}},
  {{end}}
  {{if .TimeAggs}}
  "aggs": {
    "timeAggs": {
      "date_histogram": {
        "field": "ModTime",
        "calendar_interval": "{{.TimeAggs.Interval}}",
        "format": "{{.TimeAggs.Format}}",
        "time_zone": "+08:00"
      }
    }
  },
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