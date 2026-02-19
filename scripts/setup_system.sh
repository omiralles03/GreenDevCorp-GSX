#!/bin/bash

set -e  # Exit on error

# Colors
R='\033[0;31m' 
G='\033[0;32m' 
Y='\033[1;33m' 
B='\033[0;34m' 
NC='\033[0m'

# Messages Formats
log() { echo -e "${B}[$(date +%T)]${NC} $1\n"; }
error() { echo -e "${R}[ERROR]${NC} $1\n"; exit 1; }
info() { echo -e "${B}[INFO]${NC} $1\n"; }
success() { echo -e "${G}[SUCCESS]${NC} $1\n"; }
warning() { echo -e "${Y}[WARNING]${NC} $1\n"; }


# Loading .env params
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
    log "Sourcing $ENV_FILE..."
    source "$ENV_FILE"
else
    log "No .env found, using internal defaults."
fi

VM_NAME=${VM_NAME:-debian-gsx}
VM_USER=${VM_USER:-gsx}
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
    if dpkg-query -W -f='${Status}' "$pkg" 2>dev/null | grep -q "ok installed"; then
        warning "$pkg is already installed. Skipping..."
    else
        log "Installing $pkg..."
        apt install -y "$pkg" &>/dev/null || error "Failed to install $pkg."
    fi
done

# Add user to sudo group
#   Give user all permisions on its own config file
#   Host = ( AsAnyUser : AnyGroup) Sudo
#   Hidden file => .rw-r--r--

# USER="gsx"
USER="$VM_USER"

if id -nG "$USER" | grep -qw "sudo"; then
    warning "User $USER is already in the sudo group."
else
    echo "$USER ALL=(ALL:ALL) ALL" > /etc/sudoers.d/$USER
    chmod 0440 /etc/sudoers.d/$USER
    log "User $USER added to the sudo group."
fi

# Create Admin Directory
#   Only admins group can write on this directory (rwx-rwx-r-x)
DIR="/opt/$USER-admin"
info "Creating Admin directory..."
mkdir -p "$DIR"/{scripts,backups,configs}
chown -R root:sudo "$DIR"
chmod -R 775 "$DIR"
log "Admin directory created: $DIR"

# Lock the root password for security
info "\nLocking Root password..."
# sudo passwd -l root

success "SETUP COMPLETED" 
