#!/bin/bash

. "/usr/local/lib/gsx-messages.sh"

# Ensure script is run with elevated privileges
if [ "$EUID" -ne 0 ]; then
    warning "This script must be run as sudo"
    error "Usage: sudo ./setup_system.sh"
fi

info "Starting Limitd Service Setup..."

SYSTEM_DIR="/etc/systemd/system"
CONFIG_SOURCE="/opt/admin/configs/limitd/limitd.conf"
SERVICE_SOURCE="/opt/admin/configs/limitd/limitd.service"

if [ -f "$SERVICE_SOURCE" ]; then
    run_command cp "$SERVICE_SOURCE" "$SYSTEM_DIR/limitd.service"
    log "Applied systemd service from $SERVICE_SOURCE"
else
    error "Could not find $SERVICE_SOURCE."
fi

DROPIN_DIR="/etc/systemd/system/limitd.service.d"
mkdir -p "$DROPIN_DIR"

if [ -f "$CONFIG_SOURCE" ]; then
    run_command cp "$CONFIG_SOURCE" "$DROPIN_DIR/limitd.conf"
    log "Applied systemd restart config from $CONFIG_SOURCE"
else
    error "Could not find $CONFIG_SOURCE."
fi

run_command systemctl daemon-reload
run_command systemctl enable limitd.service
run_command systemctl start limitd.service

if systemctl is-active --quiet limitd.service; then
    success "Limitd is set up and running."
else
    error "Limitd failed to start."
fi
