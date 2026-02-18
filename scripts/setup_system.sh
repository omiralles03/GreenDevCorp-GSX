#!/bin/bash

set -e  # Exit on error

# Define Error message on Exit on error
failure() {
    echo "Error ocurred on line $1"
    echo "Exiting setup..."
}
trap 'failure $LINENO' ERR



echo -n "\n--- STARTING SETUP ---\n\n" 

# Ensure script is run as root
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
#   Perfom apt update
#   Parse the package status and install if not already installed
PACKAGES=("sudo" "git" "nftables" "openssh-server" "vim")

apt update >/dev/null
for pkg in "${PACKAGES[@]}"; do
    # -W (show) -f (fromat: Status) to check if already installed
    if dpkg-query -W -f='${Status}' "$pkg" 2>dev/null | grep -q "ok installed"; then
        echo -e "$pkg is already installed. Skipping...\n"
    else
        echo -e "Installing $pkg...\n"
        apt install -y "$pkg" &>/dev/null || { echo -n "Failed to install $pkg.\n"; exit 1; }
    fi
done

# Add user to sudo group
#   Give user all permisions on its own config file
#   Host = ( AsAnyUser : AnyGroup) Sudo
#   Hidden file => .rw-r--r--
USER="gsx"

if id -nG "$USER" | grep -qw "sudo"; then
    echo -e "User $USER is already in the sudo group.\n"
else
    echo "$USER ALL=(ALL:ALL) ALL" > /etc/sudoers.d/$USER
    chmod 0440 /etc/sudoers.d/gsx
    echo -e "User $USER added to the sudo group.\n"
fi

# Create Admin Directory
#   Only admins group can write on this directory (rwx-rwx-r-x)
DIR="/opt/gsx-admin"
echo -e "Creating Admin directory...\n"
mkdir -p "$DIR"/{scripts,backups,configs}
chown -R root:sudo "$DIR"
chmod -R 775 "$DIR"
echo -e "Admin directory created: $DIR\n"

# # Verify
# echo -e "--- ACTIONS PERFORMED ---\n"
# echo -e "1. Packages:\n"
# for pkg in "${PACKAGES[@]}"; do
#     dpkg -l | grep "^ii  $pkg"
# done
# echo -e "\nUser $USER" id
# echo -e "\nAdmin directory <$DIR> with permisions:"
# ls -ld "$DIR"

# Lock the root password for security
echo -e "\nLocking Root password...\n"
sudo passwd -l root

echo -n "\t--- SETUP COMPLETED ---" 
