#!/bin/bash

# Runs the setup_system.sh without GUI post installation

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

# Loading .env params
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
    log "Sourcing $ENV_FILE..."
    source "$ENV_FILE"
else
    log "No .env found, using internal defaults."
fi

VM_NAME=${VM_NAME:-debian-gsx}
VM_USER=${VM_USER:-gsx}
VM_PASS=${VM_PASS:-admin}
H_PORT=${H_PORT:-2222}

if ! VBoxManage list vms | grep -q "\"$VM_NAME\""; then
    warning "VM '$VM_NAME' does not exists."
    error "Run 'setup_vbox.sh' first. Exiting..."
else
    info "VM '$VM_NAME' found!"
    if VBoxManage showvminfo "$VM_NAME" --machinereadable | grep -q 'VMState="poweroff"'; then
        error "VM '$VM_NAME' is not running."
    fi
fi

echo "Executing setup_system.sh inside the VM..."

# Wrapper for VBoxManage
vrun() {
    local out
    if ! out=$(VBoxManage "$@" 2>&1); then
        # error "${out#*error: }"
        echo -e "${R}[VBOX ERROR]${NC} ${out#*error: }"
        exit 1
    fi
    echo "$out" | grep -v "0%...10%" || true # Hide progress clutter
}

vrun guestcontrol "$VM_NAME" run \
    --username "$VM_USER" --password "$VM_PASS" \
    --exe "/bin/bash" -- -c "echo '$VM_PASS' | su -c /media/sf_gsx_share/scripts/setup_system.sh"

info "\nCopying SSH Keys to VM $VM_NAME..."
ssh-copy-id -p "$H_PORT" "$VM_USER"@127.0.0.1

vrun guestcontrol "$VM_NAME" run \
    --username "$VM_USER" --password "$VM_PASS" \
    --exe "/bin/bash" -- -c "echo '$VM_PASS' | sudo -S /media/sf_gsx_share/scripts/ssh_setup.sh"
