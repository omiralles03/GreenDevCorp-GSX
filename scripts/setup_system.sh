#!/bin/bash

set -e  # Exit on error

# Check if the script is being runned as ROOT
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    echo "Usage: su -c ./setup_system.sh"
    exit 1
fi

# Test internet connection
if ! ping -c 1 8.8.8.8 &>/dev/null; then
    echo "No internet connection."
    exit 1
fi

# Install the required packages
PACKAGES=("sudo" "git" "nftables" "openssh-server" "vim")

apt update >/dev/null
for pkg in "${PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg"; then
        echo -e "$pkg is already installed. Skipping...\n"
    else
        echo -e "Installing $pkg...\n"
        apt install -y "$pkg" &>/dev/null || { echo -n "Failed to install $pkg.\n"; exit 1; }
    fi
done

# Add user to sudo group
USER="gsx"

if id -nG "$USER" | grep -qw "sudo"; then
    echo -e "User $USER is already in the sudo group.\n"
else
    # usermod -aG sudo "$USER"
    echo "$USER ALL=(ALL:ALL) ALL" > /etc/sudoers.d/$USER
    chmod 0440 /etc/sudoers.d/gsx
    echo -e "User $USER added to the sudo group.\n"
fi

# Create Admin Directory
# sudo group can write
DIR="/opt/gsx-admin"
echo -e "Creating Admin directory...\n"
mkdir -p "$DIR"/{scripts,backups,configs}
chown -R root:sudo "$DIR"
chmod -R 775 "$DIR"
echo -e "Admin directory created: $DIR\n"

# Verify
echo -e "--- ACTIONS PERFORMED ---\n"
echo -e "1. Packages:\n"
for pkg in "${PACKAGES[@]}"; do
    dpkg -l | grep "^ii  $pkg"
done
echo -e "\nUser $USER" id
echo -e "\nAdmin directory <$DIR> with permisions:"
ls -ld "$DIR"

# Lock the root password for security
echo -e "\nLocking Root password...\n"
sudo passwd -l root

echo -n " --- SETUP COMPLETED ---" 
