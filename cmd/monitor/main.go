package main

import (
	"flag"
	"fmt"
	"io"
	"os"
	"slices"
	"strconv"
	"strings"
)

type Process struct {
	PID    int
	Name   string
	Memory int64
}

func main() {
	var top, all, version, asc bool

	flag.CommandLine.Init(os.Args[0], flag.ContinueOnError)
	flag.CommandLine.SetOutput(io.Discard)

	flag.BoolVar(&top, "top", false, "")
	flag.BoolVar(&top, "T", false, "")

	flag.BoolVar(&all, "all", false, "")

	flag.BoolVar(&version, "version", false, "")
	flag.BoolVar(&version, "V", false, "")

	flag.BoolVar(&asc, "asc", false, "")

	fullUsage := func() {
		fmt.Fprintf(os.Stderr, "usage: monitor <operation> [...]\n")
		fmt.Printf("\noperations:\n")
		fmt.Printf("    monitor {-h --help}\n")
		fmt.Printf("    monitor {-V --version}\n")
		fmt.Printf("    monitor {-T --top}      [options]\n")
		fmt.Printf("    monitor {-P --process}  [options]\n")
		fmt.Printf("\noptions:\n")
		fmt.Printf("    --all                   List all processes (default: DESC)\n")
		fmt.Printf("    --asc                   Sort processes by Memory (ASC)\n")
		// fmt.Printf("    --des                   Sort processes by Memory (DES)\n")
		fmt.Printf("\nuse 'monitor {-h --help}' for available options\n")
	}

	for _, arg := range os.Args {
		if arg == "-h" || arg == "--help" {
			fullUsage()
			os.Exit(0)
		}
	}

	flag.Usage = func() {
		fmt.Fprintln(os.Stderr, "error: flag provided but not recognized (use -h or --help for help)")
		os.Exit(1)
	}

	flag.Parse()

	if flag.NFlag() == 0 {
		fmt.Fprintln(os.Stderr, "error: no operation specified (use -h or --help for help)")
		os.Exit(1)
	}

	if version {
		fmt.Println("monitor v.0.1.0")
	}

	if top {
		order := -1
		if asc {
			order = 1
		}
		listProcesses(all, order)
	}

}

func listProcesses(allFlag bool, order int) {
	files, err := os.ReadDir("/proc")
	if err != nil {
		fmt.Println("Error reading /proc: ", err)
		return
	}

	var processes []Process

	for _, file := range files {
		if file.IsDir() {
			pid, err := strconv.Atoi(file.Name())
			if err != nil {
				continue // Ignore directories that are PIDs
			}

			name := getProcessName(pid)
			mem := getProcessMemory(pid)

			processes = append(processes, Process{
				PID:    pid,
				Name:   name,
				Memory: mem,
			})
		}
	}

	// Sort processes by Memory Usage
	slices.SortFunc(processes, func(a, b Process) int {
		if a.Memory > b.Memory {
			return 1 * order
		}
		if a.Memory < b.Memory {
			return -1 * order
		}
		return 0
	})

	// Column Format (%-NumOfColums)
	fmt.Printf("%-10s %-30s %-10s\n", "PID", "NAME", "RES")
	fmt.Println(strings.Repeat("-", 50))

	procCount := 0
	for _, proc := range processes {

		if proc.Memory == 0 && !allFlag {
			continue
		}

		if procCount >= 20 && !allFlag {
			break
		}

		formatMem := formatBytes(proc.Memory * 1024)
		fmt.Printf("%-10d %-30s %-10s\n", proc.PID, truncateName(proc.Name, 25), formatMem)
		procCount++
	}

}

// Parses the Process Name by its PID
// Name is found in /proc/PID/comm
func getProcessName(pid int) string {
	bytes, err := os.ReadFile(fmt.Sprintf("/proc/%d/comm", pid))
	if err != nil {
		return "Unknown"
	}
	return strings.TrimSpace(string(bytes))
}

// Parses the Process Resident Memory by its PID
// RES is found in /proc/PID/status
func getProcessMemory(pid int) int64 {
	bytes, err := os.ReadFile(fmt.Sprintf("/proc/%d/status", pid))
	if err != nil {
		return 0
	}

	lines := strings.SplitSeq(string(bytes), "\n")
	for line := range lines {
		if strings.HasPrefix(line, "VmRSS:") {
			// parts = ["VmRSS", "1234", "kb"]
			parts := strings.Fields(line)

			if len(parts) >= 2 {
				kb, err := strconv.ParseInt(parts[1], 10, 32)

				if err != nil {
					fmt.Println("Error parsing VmRSS integer: ", err)
					return 0
				}
				return kb
			}
		}
	}
	return 0
}

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
	return n[:limit] + "..."
}
