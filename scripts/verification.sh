#!/bin/bash

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

check() {
    if $1; then
        success "$2"
    else
        error "$2"
    fi
}

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

echo "--- Verification ---"

# 1. Verificar usuarios y grupos
check "id -u $VM_USER1" "User $VM_USER1 exists"
check "id -u $VM_USER2" "User $VM_USER2 exists"
check "grep -q '^sudo:' /etc/group | grep -q '$VM_USER1\|$VM_USER2'" "Users are in sudo group"

# 2. Verificar estructura de directorios de administración
for USER in "$VM_USER1" "$VM_USER2"; do
    check "[ -d /opt/$USER-admin/scripts ]" "Directory for $USER exists"
    check "[ -d /opt/$USER-admin/backups ]" "Directory for $USER exists"
    check "[ -w /opt/$USER-admin ]" "The dirctory /opt/$USER-admin is writable by $USER"
done

# 3. Verificar configuración de SSH
check "grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config" "Password authentication desactivated"
check "grep -q 'PermitRootLogin no' /etc/ssh/sshd_config" "Login as root desactivated"

# 4. Verificar llaves SSH inyectadas
for USER in "$VM_USER1" "$VM_USER2"; do
    check "[ -f /home/$USER/.ssh/authorized_keys ]" "Public key injected for $USER"
    check "[ $(stat -c %a /home/$USER/.ssh/authorized_keys) -eq 600 ]" "Correct permissions in authorized_keys for $USER"
done

success "\nAll verifications passed successfully!"