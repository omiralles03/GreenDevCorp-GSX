#!/bin/bash
. "/usr/local/lib/gsx-messages.sh"

# Ensure script is run as root
# Ensure script is run as root when run manually
if [ "$EUID" -ne 0 ]; then
    warning "This script must be run as root"
    error "Usage: su -c ./setup_system.sh"
fi
# Configure backup service for admin directories and simulate NAS mount

info "--- CONFIGURING SIMULATED NAS MOUNT ---"
NAS_MOUNT="/mnt/external_nas"

# Create the mount point
run_command mkdir -p "$NAS_MOUNT"

# Add entry to /etc/fstab if it does not exist
# Use type "vboxsf" (VirtualBox shared folder protocol)

if ! grep -q "gsx_backups" /etc/fstab; then
    echo "gsx_backups $NAS_MOUNT vboxsf defaults,rw 0 0" >> /etc/fstab
    log "Added NAS mount to /etc/fstab"
fi

run_command mount -a

if mount | grep -q "$NAS_MOUNT"; then
    success "NAS successfully mounted at $NAS_MOUNT"
else
    error "Failed to mount the NAS. Check fstab and VirtualBox Additions."
fi

info "--- CONFIGURING BACKUP SYSTEMD TIMER ---"

SERVICE_SRC="/opt/admin/configs/systemd/admin_backup.service"
TIMER_SRC="/opt/admin/configs/systemd/admin_backup.timer"
SYSTEMD_DIR="/etc/systemd/system"

# Copy files to system
if [ -f "$SERVICE_SRC" ] && [ -f "$TIMER_SRC" ]; then
    run_command cp "$SERVICE_SRC" "$SYSTEMD_DIR/"
    run_command cp "$TIMER_SRC" "$SYSTEMD_DIR/"
    log "Systemd files copied to $SYSTEMD_DIR"
else
    error "Could not find systemd unit files in configs/systemd/"
fi

# Reload systemd to read the new files
run_command systemctl daemon-reload

# Enable and start the timer
run_command systemctl enable --now admin_backup.timer

if systemctl is-active --quiet admin_backup.timer; then
    success "Backup timer is active and scheduled."
else
    error "Failed to start backup timer."
fi
