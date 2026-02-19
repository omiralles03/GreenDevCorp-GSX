#!/bin/bash

set -e

# Colors
R='\033[0;31m' 
G='\033[0;32m' 
Y='\033[1;33m' 
B='\033[0;34m' 
NC='\033[0m'

# Messages Formats
log() { echo -e "${B}[$(date +%T)]${NC} $1\n"; }
error() { echo -e "${R}[ERROR]${NC} $1\n"; exit 1; }
info() { echo -e "${B}[INFO]${NC} $1\n"; }
success() { echo -e "${G}[SUCCESS]${NC} $1\n"; }
warning() { echo -e "${Y}[WARNING]${NC} $1\n"; }

# Wrapper for VBoxManage
vrun() {
    local out
    if ! out=$(VBoxManage "$@" 2>&1); then
        echo -e "${R}[VBOX ERROR]${NC} ${out#*error: }"
        exit 1
    fi
    echo "$out" | grep -v "0%...10%" || true # Hide progress clutter
}

# Loading .env params
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
    log "Sourcing $ENV_FILE..."
    source "$ENV_FILE"
else
    log "No .env found, using internal defaults."
fi


# USE DEFAULT PARAMS IF NOT ENV FILE
VM_NAME=${VM_NAME:-debian-gsx}


# OTHER DEFAULT PARAMS
VM_USER=${VM_USER:-gsx}
VM_PASS=${VM_PASS:-admin}
VM_RAM=${VM_RAM:-2048}
VM_CPUS=${VM_CPUS:-1}
H_PORT=${H_PORT:-2222}
ISO_PATH=${ISO_PATH}
DISK_SIZE=${DISK_SIZE:-20480}
SHARED_PATH=${SHARED_PATH}
HOST_NAME=${HOST_NAME:-gsx.virtualbox.org}

# Define the search pattern for ISO file
# Find the most recent matching file
ISO_SEARCH_PATTERN="$ISO_PATH/debian-*-netinst.iso"
ISO_PATH=$(ls -t $ISO_SEARCH_PATTERN 2>/dev/null | head -n 1) 
 if [ -z "$ISO_PATH" ]; then
    error "Could not find a Debian netinst ISO in "$ISO_PATH""
else
    info "Found ISO: $ISO_PATH"
fi

# Optional: Verify CHECKSUM
info "Verifying ISO Integrity..."
ISO_DIR=$(dirname "$ISO_PATH")
ISO_FILE=$(basename "$ISO_PATH")
CHECKSUM_FILE="$ISO_DIR/SHA256SUMS"

if [ -f "$CHECKSUM_FILE" ]; then

    # Use grep to find the specific ISO hash and check it
    # Format: cd into dir to avoid path issues with sha256sum --check
    (cd "$ISO_DIR" && grep "$ISO_FILE" SHA256SUMS | sha256sum -c) || {
        error "Checksum failed! The ISO might be corrupted or tampered with."
    }
    success "ISO integrity verified.\n"
else
    warning "No SHA256SUMS file found in $ISO_DIR. Skipping verification..."
fi 

if VBoxManage list vms | grep -q "\"$VM_NAME\""; then
    warning "VM '$VM_NAME' already exists."
    log "Cleaning up old VM '$VM_NAME'..."

    # IF the VM already exists and its running (script cancelled or VM running)
    # Force stop the VM and Remove it
    if VBoxManage showvminfo "$VM_NAME" --machinereadable | grep -q 'VMState="running"'; then
        vrun controlvm "$VM_NAME" poweroff
    fi
    vrun unregistervm "$VM_NAME" --delete
    log "Removed old VM '$VM_NAME'."
fi
vrun createvm --name "$VM_NAME" --ostype "Debian_64" --register


# Shared Folder for the initial scripts
if [ ! -d "$SHARED_PATH" ]; then
    error "Shared folder path $SHARED_PATH does not exist"
fi

while ss -tuln | grep -q ":$H_PORT "; do
  log "Port $H_PORT taken, trying $((H_PORT+1))..."
  H_PORT=$((H_PORT+1))
done

log "Configuring Hardware & Network..."

vrun modifyvm "$VM_NAME" \
    --cpus "$VM_CPUS" --memory "$VM_RAM" \
    --vram 128 --graphicscontroller vmsvga \
    --mouse usbtablet --hwvirtex on \
    --nested-paging on \
    --nic1 nat --natpf1 "guestssh,tcp,,$H_PORT,,22"

log "Attaching Storage..."

vrun storagectl "$VM_NAME" --name "SATA Controller" --add sata \
    --controller IntelAhci --portcount 2

vrun createmedium disk --filename "$HOME/VirtualBox VMs/$VM_NAME/$VM_NAME.vdi" \
    --size "$DISK_SIZE" --format VDI

vrun storageattach "$VM_NAME" \
    --storagectl "SATA Controller" --port 0 --device 0 \
    --type hdd --nonrotational on \
    --medium "$HOME/VirtualBox VMs/$VM_NAME/$VM_NAME.vdi"

vrun storageattach "$VM_NAME" \
    --storagectl "SATA Controller" --port 1 --device 0 \
    --type dvddrive --medium "$ISO_PATH"

log "Adding Shared Folder..."
vrun sharedfolder add "$VM_NAME" --name "gsx_share" --hostpath "$SHARED_PATH" --automount

log "Starting Unattended Installation (Headless)..."
vrun unattended install "$VM_NAME" \
    --iso="$ISO_PATH" \
    --user="$VM_USER" --password="$VM_PASS" \
    --hostname="$VM_NAME.$HOST_NAME" \
    --install-additions \
    --start-vm=headless

log "$SUCCESS! Installation running in background. This may take a while..."
