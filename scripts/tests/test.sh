#!/bin/bash
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$BASE_DIR/../core/messages.sh"

# Calculamos la ruta correcta hacia la carpeta bootstrap desde tests
TARGET_SCRIPT="$BASE_DIR/../bootstrap/run_setup_system.sh"

# --- Automatic handover to next script ---
if [ -f "$TARGET_SCRIPT" ]; then
    info "Launching system configuration script..."
    "$TARGET_SCRIPT"
else
    error "run_setup_system.sh not found in $TARGET_SCRIPT!"
fi