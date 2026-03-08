#!/bin/bash

. "/usr/local/lib/gsx-messages.sh"
set -e

# 1. Validate that the user provided a parameter
if [ -z "$1" ]; then
    warning "Missing service parameter."
    error "Usage: $0 <service_name>"
fi

SERVICE=$1

info "=== OBSERVABILITY DIAGNOSTIC: $SERVICE ==="

# 2. Check overall status of the service
if systemctl is-active --quiet "$SERVICE"; then
    success "STATUS: ACTIVE (Running)\n"
elif systemctl is-failed --quiet "$SERVICE"; then
    warning "STATUS: FAILED (Failed)\n"
else
    info "STATUS: INACTIVE / STOPPED\n"
fi

# 3. Show official systemd state (summary)
info "--- systemctl summary ---"
run_command systemctl status "$SERVICE" --no-pager | head -n 6

# 4. Display last 15 normal logs
info "\n--- Last 15 logs in journald ---"
run_command journalctl -u "$SERVICE" -n 15 --no-pager

# 5. Filter and show ONLY errors (very handy for quick debugging)
info "--- Recent critical errors ---"
# The '-p err' flag tells journalctl to show only error messages
run_command journalctl -u "$SERVICE" -p err -n 5 --no-pager