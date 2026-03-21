#!/bin/bash
. "/usr/local/lib/gsx-messages.sh"

# Ensure script is run as root
# Ensure script is run as root when run manually
if [ "$EUID" -ne 0 ]; then
    warning "This script must be run as root"
    error "Usage: su -c ./setup_system.sh"
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

# ---- LOGROTATE ----

info "--- CONFIGURING LOGROTATE FOR BACKUPS ---"

LOGROTATE_SRC="/opt/admin/configs/logrotate/gsx_backups"
LOGROTATE_DEST="/etc/logrotate.d/gsx_backups"

if [ -f "$LOGROTATE_SRC" ]; then
    run_command cp "$LOGROTATE_SRC" "$LOGROTATE_DEST"
    run_command chown root:root "$LOGROTATE_DEST"
    run_command chmod 644 "$LOGROTATE_DEST"
    log "Logrotate configuration installed at $LOGROTATE_DEST"
else
    warning "Could not find logrotate config at $LOGROTATE_SRC"
fi