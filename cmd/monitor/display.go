package main

import (
	"fmt"
)

func formatBytes(b int64) string {
	const unit = 1024
	const sufix = "KMGT"

	if b < unit {
		return fmt.Sprintf("%d B", b)
	}

	div, exp := int64(unit), 0
	// Search the unit for b (KB, MB, GB, TB)
	// 2^10, 2^20, 2^30, 2^40
	for b >= div*unit {
		div *= unit
		exp++
	}
	result := float64(b) / float64(div)
	return fmt.Sprintf("%.2f %cB", result, sufix[exp])
}

func truncateName(n string, limit int) string {
	if len(n) <= limit {
		return n
	}
	return n[:limit] + "+"
}
