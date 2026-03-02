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


BACKUP_DIR="/opt/backups"
SOURCE_DIR="/opt"
DATE=$(date +%Y-%m-%d_%H%M%S)
FILENAME="admins_backup_$DATE.tar.gz"

# Crear directorio de destino si no existe
mkdir -p "$BACKUP_DIR"

info "Creating backup of admin directories in $BACKUP_DIR..."

# Empaquetar con -p (preservar permisos) y -z (comprimir con gzip)
tar -cvpzf "$BACKUP_DIR/$FILENAME" \
    --exclude="$BACKUP_DIR" \
    "$SOURCE_DIR"/*-admin

if [ $? -eq 0 ]; then
    success "Backup created successfully: $BACKUP_DIR/$FILENAME"
else
    error "Failed to create backup"
fi
