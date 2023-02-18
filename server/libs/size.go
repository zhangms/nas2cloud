package libs

import "fmt"

const k = 1024

func ReadableDataSize(size int64) string {
	if size <= 0 {
		return ""
	}
	value := float64(size) / k
	if value < 1 {
		return "<1KB"
	} else if value < k {
		return fmt.Sprintf("%.0fKB", value)
	}
	value = value / k
	if value < k {
		return fmt.Sprintf("%.2fMB", value)
	}
	value = value / k
	if value < k {
		return fmt.Sprintf("%.2fGB", value)
	}
	value = value / k
	if value < k {
		return fmt.Sprintf("%.2fTB", value)
	}
	value = value / k
	return fmt.Sprintf("%.2fEB", value)
}
