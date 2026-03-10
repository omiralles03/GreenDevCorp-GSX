#!/bin/bash
echo "Workload running with PID: $$"

trap "echo -e 'Received: SIGINT (Ctrl+C)\n'" SIGINT
trap "echo -e 'Received: SIGUSR1\n'" SIGUSR1
trap "echo -e 'Received: SIGUSR2\n'" SIGUSR2
trap "echo -e 'Received: SIGTERM\n'; exit 0" SIGTERM

# Cleanup function to kill subprocesses
cleanup() {
    echo "Cleaning up..."
    kill $YES_PID 2>/dev/null
    exit 0
}

trap cleanup EXIT

yes >/dev/null &
YES_PID=$!

echo "Subprocess 'yes' with PID: $YES_PID"

while true; do
    sleep 2
done
