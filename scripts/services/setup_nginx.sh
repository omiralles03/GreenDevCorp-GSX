#!/bin/bash

. "/usr/local/lib/gsx-messages.sh":

# Ensure script is run as root when run manually
if [ "$EUID" -ne 0 ]; then
    warning "This script must be run as root"
    error "Usage: su -c ./setup_system.sh"
fi

info "Starting Nginx Service Setup..."

if ! dpkg -l | grep -q nginx; then
    log "Installing Nginx package..."
    apt update && apt install -y nginx >/dev/null
else
    warning "Nginx is already installed."
fi

run_command systemctl enable nginx

# Override systemd (drop-in file) config
DROPIN_DIR="/etc/systemd/system/nginx.service.d"
mkdir -p "$DROPIN_DIR"

CONFIG_SOURCE="/opt/admin/configs/nginx/restart.conf"

if [ -f "$CONFIG_SOURCE" ]; then
    run_command cp "$CONFIG_SOURCE" "$DROPIN_DIR/restart.conf"
    log "Applied systemd restart config from $CONFIG_SOURCE"
else
    error "Could not find $CONFIG_SOURCE. Check shared folder mount."
fi

run_command systemctl daemon-reload
run_command systemctl restart nginx

if systemctl is-active --quiet nginx; then
    success "Nginx is set up and running."
else
    error "Nginx failed to start."
fi
