#!/bin/bash
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$BASE_DIR/../core/messages.sh"

# Loading .env params
ENV_FILE="$BASE_DIR/../core/.env"
if [ -f "$ENV_FILE" ]; then
    log "Sourcing $ENV_FILE..."
    source "$ENV_FILE"
else
    log "No .env found, using internal defaults."
fi

vrun guestcontrol "$VM_NAME" run \
    --username "$VM_USER1" --password "$VM_PASS" \
    --exe "//bin/bash" -- -c "echo '$VM_PASS' | sudo -S bash /opt/admin/scripts/tests/verification_w4.sh"