#!/bin/bash
# FILE NOT IN USE, WE USE SERVICE_BACKUPS.SH INSTEAD, 
# THIS IS JUST A PROOF OF CONCEPT FOR THE BACKUP SYSTEM

. "/tmp/gsx-bootstrap/scripts/core/messages.sh"
set -e

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
