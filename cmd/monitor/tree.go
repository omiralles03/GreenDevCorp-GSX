package main

import (
	"fmt"
	"strings"
)

var showPID bool

func listTree(showPids bool, metricsPID int) {
	showPID = showPids
	processes := getAllProcesses()

	// treeMap: PPID -> list of children
	// treeMap[i] = [ProcA, ProcB, ProcC, ...]
	treeMap := make(map[int][]Process)
	var targetProcess *Process
	for _, p := range processes {
		treeMap[p.PPID] = append(treeMap[p.PPID], p)

		if metricsPID != 0 && p.PID == metricsPID {
			targetProcess = &p
		}
	}

	fmt.Println("Process Tree")
	fmt.Println(strings.Repeat("=", 30))

	// 0: include kernel level
	// 1: skip kernel level
	if metricsPID != 0 {
		if targetProcess != nil {
			if showPID {
				fmt.Printf("%s (%d)\n", targetProcess.Name, targetProcess.PID)
			} else {
				fmt.Printf("%s\n", targetProcess.Name)
			}
		} else {
			fmt.Printf("Error: PID %d not found\n", metricsPID)
		}

	}
	drawBranch(metricsPID, treeMap, "")
}

func drawBranch(parentPID int, treeMap map[int][]Process, indent string) {
	children, ok := treeMap[parentPID]
	if !ok {
		return
	}

	for i, child := range children {
		isLast := (i == len(children)-1)

		connector := "├── "
		if isLast {
			connector = "└── "
		}

		if showPID {
			fmt.Printf("%s%s%s (%d)\n", indent, connector, child.Name, child.PID)
		} else {
			fmt.Printf("%s%s%s\n", indent, connector, child.Name)
		}

		// Indent for the childs in the next call of drawBranch
		newIndent := indent
		if isLast {
			newIndent += "    "
		} else {
			newIndent += "│   "
		}

		drawBranch(child.PID, treeMap, newIndent)
	}
}
