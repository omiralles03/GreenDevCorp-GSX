#!/bin/bash

set -e                                          # Exit on error
export PATH=$PATH:/usr/bin:/usr/sbin:/bin:/sbin # Ensure standard paths are included

# Colors
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
B='\033[0;34m'
NC='\033[0m'

# Messages Formats
log() { echo -e "${B}[$(date +%T)]${NC} $1\n"; }
error() {
    echo -e "${R}[ERROR]${NC} $1\n"
    exit 1
}
info() { echo -e "${B}[INFO]${NC} $1\n"; }
success() { echo -e "${G}[SUCCESS]${NC} $1\n"; }
warning() { echo -e "${Y}[WARNING]${NC} $1\n"; }

# Loading .env params
ENV_FILE="/media/sf_gsx_share/scripts/.env"
if [ -f "$ENV_FILE" ]; then
    info "Sourcing $ENV_FILE in shared folder..."
    source "$ENV_FILE"
else
    warning "No .env found, using internal defaults."
fi

VM_NAME=${VM_NAME:-debian-gsx}
VM_USER1=${VM_USER1:-admin1}
VM_USER2=${VM_USER2:-admin2}
VM_PASS=${VM_PASS:-admin}

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    warning "This script must be run as root"
    error "Usage: su -c ./setup_system.sh"
fi

log "STARTING SETUP..."

# Test internet connection
if ! ping -c 1 8.8.8.8 &>/dev/null; then
    error "No internet connection."
else
    info "Internet connection established"
fi

# Install the required packages
#   Perfom apt update
#   Parse the package status and install if not already installed
PACKAGES=("sudo" "git" "nftables" "openssh-server" "vim")

apt update >/dev/null
for pkg in "${PACKAGES[@]}"; do
    # -W (show) -f (fromat: Status) to check if already installed
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
        warning "$pkg is already installed. Skipping..."
    else
        log "Installing $pkg..."
        apt install -y "$pkg" &>/dev/null || error "Failed to install $pkg."
    fi
done

# Add users to sudo group
#   Give user all permisions on its own config file
#   Host = ( AsAnyUser : AnyGroup) Sudo
#   Hidden file => .rw-r--r--

ADMINS=("$VM_USER1" "$VM_USER2")

for USER in "${ADMINS[@]}"; do
    if ! id "$USER" &>/dev/null; then
        log "Creating user $USER..."
        useradd -m -s /bin/bash "$USER"
        echo "$USER:$VM_PASS" | chpasswd
    fi
    if id -nG "$USER" | grep -qw "sudo"; then
        warning "User $USER is already in the sudo group."
    else
        echo "$USER ALL=(ALL:ALL) ALL" >/etc/sudoers.d/$USER
        chmod 0440 /etc/sudoers.d/$USER
        log "User $USER added to the sudo group."
    fi
done

# Create Admin Directory
#   Only admins group can write on this directory (rwx-rwx-r-x)

for USER in "${ADMINS[@]}"; do
    DIR="/opt/$USER-admin"
    info "Creating Admin directory..."
    mkdir -p "$DIR"/{scripts,backups,configs}
    chown -R root:sudo "$DIR"
    chmod -R 775 "$DIR"
    log "$USER admin directory created: $DIR"
done

KEY_DIR="//media/sf_gsx_share/keys"
for key_file in "$KEY_DIR"/*.pub; do

    FILENAME=$(basename "$key_file")
    TARGET_USER="${FILENAME%%_*}"

    info "Copying key $FILENAME for $TARGET_USER..."

    mkdir -p /home/$TARGET_USER/.ssh
    cat $KEY_DIR/$FILENAME >>/home/$TARGET_USER/.ssh/authorized_keys
    chown -R $TARGET_USER:$TARGET_USER /home/$TARGET_USER/.ssh
    chmod 700 /home/$TARGET_USER/.ssh
    chmod 600 /home/$TARGET_USER/.ssh/authorized_keys
done

/bin/bash /media/sf_gsx_share/scripts/ssh_setup.sh

# Lock the root password for security
info "\nLocking Root password..."
# sudo passwd -l root

success "SETUP COMPLETED"
