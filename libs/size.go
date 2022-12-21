package libs

import "fmt"

func ReadableDataSize(size int64) string {
	value := float64(size) / 1024
	if value < 1 {
		return "<1KB"
	} else if value < 1024 {
		return fmt.Sprintf("%.0fKB", value)
	}
	value = value / 1024
	if value < 1024 {
		return fmt.Sprintf("%.2fMB", value)
	}
	value = value / 1024
	if value < 1024 {
		return fmt.Sprintf("%.2fGB", value)
	}
	value = value / 1024
	if value < 1024 {
		return fmt.Sprintf("%.2fTB", value)
	}
	value = value / 1024
	return fmt.Sprintf("%.2fEB", value)
}
