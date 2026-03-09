package main

import (
	"flag"
	"fmt"
	"io"
	"os"
	"time"
)

func main() {
	var top, all, version, asc, tree, showPids, cpu bool
	var metricsPID int

	flag.CommandLine.Init(os.Args[0], flag.ContinueOnError)
	flag.CommandLine.SetOutput(io.Discard)

	flag.BoolVar(&top, "top", false, "")
	flag.BoolVar(&top, "T", false, "")

	flag.BoolVar(&all, "all", false, "")

	flag.BoolVar(&version, "version", false, "")
	flag.BoolVar(&version, "v", false, "")

	flag.BoolVar(&asc, "asc", false, "")
	flag.BoolVar(&cpu, "cpu", false, "")

	flag.BoolVar(&tree, "t", false, "")
	flag.BoolVar(&tree, "tree", false, "")

	flag.BoolVar(&showPids, "show-pids", false, "")

	flag.IntVar(&metricsPID, "m", 0, "")

	fullUsage := func() {
		fmt.Fprintf(os.Stderr, "usage: monitor <operation> [...]\n")
		fmt.Printf("\noperations:\n")
		fmt.Printf("    monitor {-h --help}\n")
		fmt.Printf("    monitor {-v --version}\n")
		fmt.Printf("    monitor {-T --top}      [options]\n")
		fmt.Printf("    monitor {-t --tree}     [options]\n")
		fmt.Printf("\noptions:\n")
		fmt.Printf("    [top] --all             List all processes (default: DESC)\n")
		fmt.Printf("    [top] --asc             Sort processes (ASC)\n")
		fmt.Printf("    [top] --cpu             Sort processes by CPU\n")
		fmt.Printf("    [top] --m <PID>         Display metrics for process <PID>\n")
		fmt.Printf("    [tree] --show-pids      Show PID in the tree\n")
		fmt.Printf("    [tree] --m <PID>        Dsiplay tree for process <PID>\n")
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
		fmt.Println("monitor v.1.0.0")
	}

	if top {
		order := -1
		if asc {
			order = 1
		}

		// Hide cursor for smoother display
		fmt.Print("\033[?25l")
		defer fmt.Print("\033[?25h")

		// Clear screen once at the start
		fmt.Print("\033[2J")

		for {
			// Move cursor to top-left without clearing
			fmt.Print("\033[H")
			listProcesses(all, cpu, order, metricsPID)
			time.Sleep(500 * time.Millisecond)
		}
	}
	if tree {
		fmt.Print("\033[H\033[2J")
		listTree(showPids, metricsPID)
	}
}
