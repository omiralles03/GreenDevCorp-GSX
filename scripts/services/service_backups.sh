#!/bin/bash

. "/usr/local/lib/gsx-messages.sh"
#set -e
# we comment set -e to handle errors gracefully and log them instead of exiting immediately

BACKUP_DIR="/mnt/backups"
DATE=$(date +%Y-%m-%d__%H_%M_%S)
FILE_NAME="server_backup_$DATE.tar.gz"
SOURCE_DIRS=("/opt" "/home" "/etc" "/usr/local" "/root")
LOG_FILE="/var/log/gsx_backups.log"

if [ ! -d "$BACKUP_DIR" ] || [ ! -w "$BACKUP_DIR" ]; then
    log_file "$LOG_FILE" "ERROR" "Backup mount $BACKUP_DIR is not writable or not mounted!"
    error "Backup drive is not accessible!"
fi

log_file "$LOG_FILE" "INFO" "Starting tar system backup from $SOURCE_DIR to $BACKUP_DIR..."
info "Running full backup (tar) to Simulated NAS..."

# Run tar. Redirect stderr (2>&1) so any tar failures are logged.
tar -czf "$BACKUP_DIR/$FILE_NAME" "${SOURCE_DIRS[@]}" "$BACKUP_DIR/" >> "$LOG_FILE" 2>&1

# TAR return 0 if successful, 1 if it have warnings, or any other value if an error occurred.
TAR_EXIT_CODE=$?
if [ $TAR_EXIT_CODE -eq 0 ] || [ $TAR_EXIT_CODE -eq 1 ]; then
    log_file "$LOG_FILE" "SUCCESS" "Tar backup completed successfully at $BACKUP_DIR/$FILE_NAME"
    success "Backup created successfully on $BACKUP_DIR"
else
    log_file "$LOG_FILE" "ERROR" "tar command failed with code $TAR_EXIT_CODE"
    error "Failed to create backup"
fi
