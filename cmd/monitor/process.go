package main

import (
	"fmt"
	"os"
	"os/user"
	"runtime"
	"slices"
	"strconv"
	"strings"
)

const maxProcTop = 30 // Max process to list by default in --top
const Hertz = 100     // Default in most Linux systems (getconf CLK_TCK)
var cpuCores = runtime.NumCPU()

type Process struct {
	PID      int
	PPID     int
	Name     string
	State    string // "R", "S", "Z"
	Memory   int64  // KB
	CPUTicks uint64
	CPUUsage float64
}

func listProcesses(allFlag, cpu bool, order, metricsPID int) {

	processes := getAllProcesses()

	printSystemStats(processes)

	if metricsPID != 0 {

		status, _ := os.ReadFile(fmt.Sprintf("/proc/%d/status", metricsPID))
		lines := strings.Split(string(status), "\n")
		threads := getValueByKey("Threads:", lines, 1)

		uid := getValueByKey("Uid:", lines, 1)
		uidStr := fmt.Sprintf("%.0f", uid)
		u, _ := user.LookupId(uidStr)

		fds, _ := os.ReadDir(fmt.Sprintf("/proc/%d/fd", metricsPID))

		fmt.Printf("%-7s %-7s %-9s %-7s %-5s %-5s %-7s %-7s %-12s %-20s\n",
			"PID", "PPID", "USER", "STATE", "THR", "fds", "%CPU", "%CPU/c", "RES", "NAME")

		fmt.Println(strings.Repeat("-", 90))
		proc, _ := getProcessData(metricsPID)
		fmt.Printf("%-7d %-7d %-9s %-7s %-5d %-5d %-7.2f %-7.2f %-12s %-20s\n",
			proc.PID,
			proc.PPID,
			truncateName(u.Username, 7),
			"  "+proc.State,
			int64(threads),
			len(fds),
			proc.CPUUsage,
			proc.CPUUsage/float64(cpuCores),
			formatBytes(proc.Memory*1024),
			truncateName(proc.Name, 10),
		)

	} else {

		slices.SortFunc(processes, func(a, b Process) int {
			if cpu {
				if a.CPUUsage > b.CPUUsage {
					return 1 * order
				}
				if a.CPUUsage < b.CPUUsage {
					return -1 * order
				}
				return 0
			} else {
				if a.Memory > b.Memory {
					return 1 * order
				}
				if a.Memory < b.Memory {
					return -1 * order
				}
				return 0
			}
		})

		fmt.Printf("%-7s %-7s %-7s %-7s %-9s %-12s %-20s\n", "PID", "PPID", "STATE", "%CPU", "%CPU/c", "RES", "NAME")
		fmt.Println(strings.Repeat("-", 90))

		procCount := 0
		for _, proc := range processes {

			if proc.Memory == 0 && !allFlag {
				continue
			}

			if procCount >= maxProcTop && !allFlag {
				break
			}

			fmt.Printf("%-7d %-7d %-7s %-8.2f %-8.2f %-12s %-20s\n",
				proc.PID,
				proc.PPID,
				"  "+proc.State,
				proc.CPUUsage,
				proc.CPUUsage/float64(cpuCores),
				formatBytes(proc.Memory*1024),
				proc.Name,
			)
			procCount++
		}
	}

}

// Read all process info from /proc/[pid]/stat
func getProcessData(pid int) (Process, error) {
	bytes, err := os.ReadFile(fmt.Sprintf("/proc/%d/stat", pid))
	if err != nil {
		return Process{}, err
	}

	// Parse the different values from /proc/[pid]/stat
	sBytes := string(bytes)

	iniDelimiter := strings.Index(sBytes, "(")
	endDelimiter := strings.LastIndex(sBytes, ")")
	name := sBytes[iniDelimiter+1 : endDelimiter]

	// Rest of the fields start after (Name)
	// Avoids names that include white spaces indide ()
	fields := strings.Fields(sBytes[endDelimiter+2:])

	// Refer to https://www.man7.org/linux/man-pages//man5/proc_pid_stat.5.html
	// All fields are offsetted by -3
	state := fields[0]
	ppid, _ := strconv.Atoi(fields[1])
	utime, _ := strconv.ParseUint(fields[11], 10, 64)
	stime, _ := strconv.ParseUint(fields[12], 10, 64)
	starttime, _ := strconv.ParseUint(fields[19], 10, 64)

	// Calculate CPU usage for the process
	totalTime := float64(utime + stime)
	uptime := getSystemUptime()
	seconds := uptime - (float64(starttime) / float64(Hertz))

	cpuUsage := 0.0
	if seconds > 0 {
		cpuUsage = 100 * ((totalTime / float64(Hertz)) / seconds)
	}

	// Get Resident Memory
	status, _ := os.ReadFile(fmt.Sprintf("/proc/%d/status", pid))
	lines := strings.Split(string(status), "\n")
	memory := getValueByKey("VmRSS", lines, 1)

	return Process{
		PID:      pid,
		PPID:     ppid,
		Name:     name,
		State:    state,
		Memory:   int64(memory),
		CPUTicks: utime + stime,
		CPUUsage: cpuUsage,
	}, nil
}

// Gets the System uptime from /proc/uptime
func getSystemUptime() float64 {
	bytes, _ := os.ReadFile("/proc/uptime")
	fields := strings.Fields(string(bytes))
	uptime, _ := strconv.ParseFloat(fields[0], 64)
	return uptime
}

func getAllProcesses() []Process {
	var processes []Process

	files, err := os.ReadDir("/proc")
	if err != nil {
		fmt.Println("Error reading /proc: ", err)
		os.Exit(1)
	}

	for _, file := range files {
		pid, err := strconv.Atoi(file.Name())
		if err == nil {
			p, err := getProcessData(pid)
			if err != nil {
				continue
			}
			processes = append(processes, p)
		}
	}
	return processes
}

func printSystemStats(processes []Process) {
	load, _ := os.ReadFile("/proc/loadavg")
	fmt.Printf("load average: %s", string(load))

	var r, s, z, t int
	for _, p := range processes {
		switch p.State {
		case "R":
			r++
		case "S", "D":
			s++
		case "Z":
			z++
		case "T":
			t++
		}
	}

	fmt.Printf("Tasks: %d total, %d running, %d sleeping, %d stopped, %d zombie\n",
		len(processes), r, s, t, z)

	meminfo, _ := os.ReadFile("/proc/meminfo")
	lines := strings.Split(string(meminfo), "\n")

	total := getValueByKey("MemTotal:", lines, 1)
	free := getValueByKey("MemFree:", lines, 1)
	buff := getValueByKey("Buffers:", lines, 1)
	cache := getValueByKey("Cached:", lines, 1)
	sRecl := getValueByKey("SReclaimable:", lines, 1)

	buffCache := buff + cache + sRecl
	used := total - free - buffCache

	fmt.Printf("Mem: %s total, %s free, %s used, %s buff/cache\n\n",
		formatBytes(int64(total)*1024),
		formatBytes(int64(free)*1024),
		formatBytes(int64(used)*1024),
		formatBytes(int64(buffCache)*1024),
	)
}

func getValueByKey(label string, lines []string, field int) float64 {
	for _, line := range lines {
		if strings.HasPrefix(line, label) {
			fields := strings.Fields(line)
			if len(fields) >= 2 {
				val, _ := strconv.ParseFloat(fields[field], 64)
				return val
			}
		}
	}
	return 0
}
