#!/bin/bash
. "/usr/local/lib/gsx-messages.sh"
set -e

info "Starting services setup inside the VM..."

# ---- NGINX ---
bash "/tmp/gsx-bootstrap/scripts/services/setup_nginx.sh"

# ---- Backups ----
bash "/tmp/gsx-bootstrap/scripts/services/setup_admins_backups.sh"

success "Services setup completed successfully."