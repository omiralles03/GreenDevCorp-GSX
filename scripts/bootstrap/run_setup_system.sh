#!/bin/bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$BASE_DIR/../core/messages.sh"

# Runs the setup_system.sh without GUI post installation

# Loading .env params
ENV_FILE="$BASE_DIR/../core/.env"
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
        warning "VM '$VM_NAME' is not running."
        info "Starting it now (headless)..."
        vrun startvm "$VM_NAME" --type headless
    fi
fi

#  The OS might be booting while the VM is "Running"
info "Waiting for Guest Additions to be ready..."
until VBoxManage guestcontrol "$VM_NAME" run --username "$VM_USER1" --password "$VM_PASS" --exe "/usr/bin/id" &>/dev/null; do
    echo -n "."
    sleep 5
done
echo -e "\n"

# ---- TEMPORAL INSTALLATION FOLDER ----

info "Creating temporal installation folder"

vrun guestcontrol "$VM_NAME" mkdir "/tmp/gsx-bootstrap" \
    --username "$VM_USER1" --password "$VM_PASS"

vrun guestcontrol "$VM_NAME" copyto "$SHARED_PATH" \
    --target-directory "/tmp/gsx-bootstrap" \
    --username "$VM_USER1" --password "$VM_PASS" \
    --recursive

success "Created temporal installation folders"

# ---- EXECUTING SETUP SCRIPTS ----

echo -e "\n"
info "Executing setup_system.sh inside the VM..."

vrun guestcontrol "$VM_NAME" run \
    --username "$VM_USER1" --password "$VM_PASS" \
    --exe "/bin/bash" -- -c "echo '$VM_PASS' | su -c 'bash /tmp/gsx-bootstrap/scripts/bootstrap/setup_system.sh'"

vrun guestcontrol "$VM_NAME" run \
    --username "$VM_USER1" --password "$VM_PASS" \
    --exe "/bin/bash" -- -c "echo '$VM_PASS' | su -c 'bash /tmp/gsx-bootstrap/scripts/bootstrap/backups.sh'"

# ----- COPY FILES TO ADMIN DIRECTORIES -----
echo -n
info "Copying messages.sh to /usr/local/lib ..."
vrun guestcontrol "$VM_NAME" run \
    --username "$VM_USER1" --password "$VM_PASS" \
    --exe "/bin/bash" -- -c "echo '$VM_PASS' | su -c 'cp /tmp/gsx-bootstrap/scripts/core/messages.sh /usr/local/lib/gsx-messages.sh && chmod 644 /usr/local/lib/gsx-messages.sh'"

echo -e
info "Removing temporal folder..."

vrun guestcontrol "$VM_NAME" run \
    --username "$VM_USER1" --password "$VM_PASS" \
    --exe "/bin/rm" -- -rf "/tmp/gsx-bootstrap"

# Lock the root password for security
info "\nLocking Root password..."
vrun guestcontrol "$VM_NAME" run \
    --username "$VM_USER1" --password "$VM_PASS" \
    --exe "/bin/bash" -- -c "echo '$VM_PASS' | su -c 'passwd -l root'"

echo -e
success "System setup completed successfully!"
