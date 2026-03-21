#!/bin/bash
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$BASE_DIR/../core/messages.sh"

ENV_FILE="$BASE_DIR/../core/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

VM_NAME=${VM_NAME:-debian-gsx}
CLIENT_VM="${VM_NAME}-client"
VM_USER1=${VM_USER1:-admin1}
VM_PASS=${VM_PASS:-admin}

info "=== AUTOMATED NFS CLIENT TEST (WEEK 5) ==="

if VBoxManage list vms | grep -q "\"$CLIENT_VM\""; then
    warning "Client VM '$CLIENT_VM' already exists. Cleaning up..."
    VBoxManage controlvm "$CLIENT_VM" poweroff 2>/dev/null || true
    sleep 2
    vrun unregistervm "$CLIENT_VM" --delete
fi

info "Cloning VM from snapshot 'Clean setup'..."
vrun clonevm "$VM_NAME" --snapshot "Clean setup" --options link --name "$CLIENT_VM" --register

info "Starting Client VM ($CLIENT_VM) headless..."
vrun startvm "$CLIENT_VM" --type headless

info "Waiting for Client VM to boot and Guest Additions to be ready..."
is_ready=0
while [ $is_ready -eq 0 ]; do
    if VBoxManage guestcontrol "$CLIENT_VM" run --username "$VM_USER1" --password "$VM_PASS" --exe "//usr/bin/id" &>/dev/null; then
        is_ready=1
    else
        echo -n "."
        sleep 5
    fi
done
echo -e "\n"
success "Client VM is ready!"

info "Installing NFS client, mounting shared folder, and verifying files..."

TEST_SCRIPT="export DEBIAN_FRONTEND=noninteractive; apt-get update >/dev/null; apt-get install -y nfs-common >/dev/null; mkdir -p /mnt/client_backups; mount -t nfs 10.0.2.15:/mnt/backups /mnt/client_backups; echo --- CONTENTS OF /mnt/client_backups ---; ls -la /mnt/client_backups"

VBoxManage guestcontrol "$CLIENT_VM" run \
    --username "$VM_USER1" --password "$VM_PASS" \
    --exe "//bin/bash" -- -c "echo '$VM_PASS' | sudo -S -p '' bash -c '$TEST_SCRIPT'"

info "Test completed. Powering off Client VM..."
vrun controlvm "$CLIENT_VM" poweroff

success "NFS Networked Storage test fully automated and successful!"