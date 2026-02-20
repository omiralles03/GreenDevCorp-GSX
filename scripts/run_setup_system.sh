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
VM_USER1=${VM_USER1:-admin1}
VM_USER2=${VM_USER2:-admin2}
VM_PASS=${VM_PASS:-admin}
H_PORT=${H_PORT:-2222}

ADMINS=("$VM_USER1" "$VM_USER2")

if ! VBoxManage list vms | grep -q "\"$VM_NAME\""; then
    warning "VM '$VM_NAME' does not exists."
    error "Run 'setup_vbox.sh' first. Exiting..."
else
    info "VM '$VM_NAME' found!"
    if VBoxManage showvminfo "$VM_NAME" --machinereadable | grep -q 'VMState="poweroff"'; then
        error "VM '$VM_NAME' is not running."
    fi
fi

#  The OS might be booting while the VM is "Running"
info "Waiting for Guest Additions to be ready..."
until VBoxManage guestcontrol "$VM_NAME" run --username "$VM_USER1" --password "$VM_PASS" --exe "//usr/bin/id" &>/dev/null; do
    echo -n "."
    sleep 5
done
echo -e "\n"

info "Executing setup_system.sh inside the VM..."
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
    --username "$VM_USER1" --password "$VM_PASS" \
    --exe "//bin/bash" -- -c "echo '$VM_PASS' | su -c '//bin/bash //media/sf_gsx_share/scripts/setup_system.sh'"

for USER in "${ADMINS[@]}"; do
    info "Copying SSH Public Key for $USER..." 
    ssh-copy-id -p "$H_PORT" -o StrictHostKeyChecking=no "$USER"@127.0.0.1 &>/dev/null || warning "Failed to copy SSH key for $USER"
done

vrun guestcontrol "$VM_NAME" run \
    --username "$VM_USER1" --password "$VM_PASS" \
    --exe "//bin/bash" -- -c "echo '$VM_PASS' | su -c /media/sf_gsx_share/scripts/ssh_setup.sh"

success "System setup completed successfully!"
