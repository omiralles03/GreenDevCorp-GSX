#!/bin/bash

. messages

# Loading .env params
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
    log "Sourcing $ENV_FILE..."
    source "$ENV_FILE"
else
    log "No .env found, using internal defaults."
fi

echo "VM_NAME: $VM_NAME"
echo "VM_USER1: $VM_USER1"
echo "VM_USER2: $VM_USER2"
echo "VM_RAM: $VM_RAM"
echo "VM_CPUS: $VM_CPUS"
echo "DISK_SIZE: $DISK_SIZE"
echo "ISO_PATH: $ISO_PATH"
echo "SHARED_PATH: $SHARED_PATH"
echo "VM_PASS: $VM_PASS"
echo "H_PORT: $H_PORT"

# Simple progress bar function
draw_progress() {
    local width=40
    local perc=$1
    local filled=$((perc * width / 100))
    local empty=$((width - filled))
    printf "\r${B}[INFO]${NC} Progress: ["
    printf "%${filled}s" | tr ' ' '#'
    printf "%${empty}s" | tr ' ' '-'
    printf "] %d%%" "$perc"
}

start_time=$(date +%s)
timeout=1320 # 22 minutes
is_ready=0
progress=0

is_ready=0
while [ $is_ready -eq 0 ]; do
    # Try to execute a simple command inside the VM
    if VBoxManage guestcontrol "$VM_NAME" run --username "$VM_USER1" --password "$VM_PASS" --exe "//usr/bin/id" &>/dev/null; then
        is_ready=1
        progress=100
    else
        # Update progress based on time (simulated up to 99%)
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))

        if [ $elapsed -gt $timeout ]; then
            echo -e "\n"
            error "Installation timed out. Please check the VM manually."
        fi

        # Calculate simulated progress (0 to 99%)
        progress=$(((elapsed * 99) / timeout))
        [ $progress -gt 99 ] && progress=99
    fi

    draw_progress $progress
    sleep 10
done

ADMINS=("$VM_USER1" "$VM_USER2")

for USER in "${ADMINS[@]}"; do
    if ! id "$USER" &>/dev/null; then
        echo "Creating user $USER..."
    else
        echo "User $USER already exists. Skipping..."
    fi
done

