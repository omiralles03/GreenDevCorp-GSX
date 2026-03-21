#!/bin/bash
export PATH=$PATH:/usr/bin:/usr/sbin:/bin:/sbin
. "/usr/local/lib/gsx-messages.sh"


if [ "$EUID" -ne 0 ]; then
    warning "This script must be run as root"
    error "Usage: sudo ./setup_nfs_server.sh"
fi

info "--- CONFIGURING NFS SERVER FOR NETWORKED STORAGE ---"

if ! dpkg -l | grep -q nfs-kernel-server; then
    log "Installing nfs-kernel-server..."
    apt-get update >/dev/null
    apt-get install -y nfs-kernel-server >/dev/null
fi

SHARED_DIR="/mnt/backups"
mkdir -p "$SHARED_DIR"

EXPORT_LINE="$SHARED_DIR 10.0.2.0/24(rw,sync,no_subtree_check,no_root_squash)"

if ! grep -q "^$SHARED_DIR" /etc/exports; then
    echo "$EXPORT_LINE" >> /etc/exports
    log "Added $SHARED_DIR export to /etc/exports"
else
    warning "NFS export for $SHARED_DIR already exists."
fi

run_command exportfs -ra
run_command systemctl enable --now nfs-kernel-server
run_command systemctl restart nfs-kernel-server

if systemctl is-active --quiet nfs-kernel-server; then
    success "NFS Server successfully sharing $SHARED_DIR to the network"
else
    error "Failed to start NFS server"
fi