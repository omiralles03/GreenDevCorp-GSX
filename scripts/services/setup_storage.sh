#!/bin/bash

. "/usr/local/lib/gsx-messages.sh"
export PATH=$PATH:/usr/sbin:/sbin:/usr/local/sbin

# Ensure script is run with elevated privileges
if [ "$EUID" -ne 0 ]; then
    warning "This script must be run as sudo"
    error "Usage: sudo ./setup_system.sh"
fi

if ! dpkg -l | grep -q parted; then
    log "Installing parted package..."
    apt update && apt install -y parted >/dev/null
else
    warning "parted is already installed."
fi

if ! dpkg -l | grep -q xfsprogs; then
    log "Installing xfsprogs package..."
    apt update && apt install -y xfsprogs >/dev/null
else
    warning "xfsprogs is already installed."
fi

DEVICE="/dev/sdb"
MOUNT_POINT="/mnt/backups"

info "Setting up disk partitions"

if [ ! -b "$DEVICE" ]; then
    error "Device $DEVICE does not physically exist."
fi

if blkid "$DEVICE"1 >>/dev/null 2>&1; then
    warning "Disk is already formatted, skipping partitioning..."
else
    info "Partitioning device $DEVICE ..."

    # Partitioning with parted GPT
    run_command parted -s $DEVICE mklabel gpt
    run_command parted -s $DEVICE mkpart primary xfs 0% 100%
    sleep 1

    # Format /dev/sdb1
    run_command mkfs.xfs -f "${DEVICE}1"
fi

mkdir -p $MOUNT_POINT

# Add entry to fstab
UUID=$(blkid -s UUID -o value "${DEVICE}1")

if grep -q "$MOUNT_POINT" /etc/fstab; then
    log "Mounting point $MOUNT_POINT is already on /etc/fstab. Updating UUID..."
    sed -i "\| $MOUNT_POINT |d" /etc/fstab
fi

log "Adding mounting point to /etc/fstab"
echo "UUID=$UUID  $MOUNT_POINT  xfs  defaults  0  2" >>/etc/fstab

success "Completed storage disk setup"

mount -a
