#!/bin/bash
. "/usr/local/lib/gsx-messages.sh"

if [ "$EUID" -ne 0 ]; then
    error "Usage: sudo ./test_backups.sh"
fi

BACKUP_DIR="/mnt/backups"
RESTORE_DIR="/tmp/restore_test"

info "=== AUTOMATED BACKUP INTEGRITY & RESTORE TEST ==="

LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/server_backup_*.tar.gz 2>/dev/null | head -n 1)

if [ -z "$LATEST_BACKUP" ]; then
    error "No backup files found in $BACKUP_DIR"
fi
log "Latest backup found: $(basename "$LATEST_BACKUP")"

info "Checking archive integrity (tar -tzf)..."
if tar -tzf "$LATEST_BACKUP" > /dev/null 2>&1; then
    success "Archive is structurally sound. Integrity OK."
else
    error "Archive is corrupted!"
fi

info "Testing restore procedure to alternate location ($RESTORE_DIR)..."
rm -rf "$RESTORE_DIR"
mkdir -p "$RESTORE_DIR"

if tar -xzf "$LATEST_BACKUP" -C "$RESTORE_DIR" > /dev/null 2>&1; then
    success "Files extracted successfully to $RESTORE_DIR"
else
    error "Failed to extract files during restore test."
fi

info "Verifying presence of critical directories..."
MISSING=0
CRITICAL_DIRS=("opt" "etc" "home" "root" "usr/local")

for dir in "${CRITICAL_DIRS[@]}"; do
    if [ -d "$RESTORE_DIR/$dir" ]; then
        log "Directory /$dir is present."
    else
        warning "Directory /$dir is MISSING!"
        MISSING=$((MISSING + 1))
    fi
done

if [ "$MISSING" -eq 0 ]; then
    success "All critical directories verified in restored backup."
else
    error "Backup is incomplete. Missing $MISSING critical directories."
fi

rm -rf "$RESTORE_DIR"
success "Backup verification completed successfully!"