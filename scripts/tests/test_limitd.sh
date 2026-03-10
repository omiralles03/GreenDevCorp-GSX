#!/bin/bash
. "/usr/local/lib/gsx-messages.sh"

# Ensure script is run with elevated privileges
if [ "$EUID" -ne 0 ]; then
    warning "This script must be run as sudo"
    error "Usage: sudo ./test_limitd.sh"
fi

SERVICE_FILE="/etc/systemd/system/limitd.service"

info "--- Resource Limiting (OOM Killer) ---"
info "Setting up limitd.service to force Out-Of-Memory..."

run_command cp $SERVICE_FILE "${SERVICE_FILE}.bak"

# Overwrite the service
# Loop that doubles a until MemoryMax is reached
# Disable using SwapMemory after reaching MemoryMax
sed -i 's|^ExecStart=.*|ExecStart=/bin/bash -c "a=\\\"x\\\"; while true; do a=\\\"\$a\$a\\\"; done"|' $SERVICE_FILE
if ! grep -q "MemorySwapMax" $SERVICE_FILE; then
    sed -i '/\[Service\]/a MemorySwapMax=0' $SERVICE_FILE
fi

run_command systemctl daemon-reload
run_command systemctl restart limitd.service

info "Waiting for process to exceed 60MB..."

isKilled=0
while [ "$isKilled" -eq 0 ]; do
    sleep 2
    if systemctl status limitd.service | grep -q "oom-kill"; then
        echo -e "\n"
        success "Service killed by OOM."
        #systemctl status limitd.service | grep -E "Active:|Main PID:|status="
        systemctl status limitd.service
        isKilled=1
    else
        warning "Service not reached 60MB yet."
        systemctl status limitd.service
    fi
done

# Restore service
sed -i 's|ExecStart=.*|ExecStart=/bin/bash -c "/usr/bin/yes > /dev/null"|' $SERVICE_FILE
run_command mv "${SERVICE_FILE}.bak" $SERVICE_FILE
run_command systemctl daemon-reload
run_command systemctl restart limitd.service
success "Service restored to defaults"
run_command systemctl status limitd.service

info "cgroups verification:"
echo -e "/sys/fs/cgroup/system.slice/limitd.service/cpu.max\n"
echo -e "usage(ms) : time(ms)\n"
cat /sys/fs/cgroup/system.slice/limitd.service/cpu.max
