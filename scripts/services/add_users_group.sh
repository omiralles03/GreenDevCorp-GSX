#!/bin/bash
. "/usr/local/lib/gsx-messages.sh"
set -e
export PATH=$PATH:/usr/bin:/usr/sbin:/bin:/sbin

# Ensure script is run with elevated privileges
if [ "$EUID" -ne 0 ]; then
    warning "This script requires elevated privileges."
    error "Usage: sudo $0 <number_of_users> <group_name>"
fi

# Check if parameters are provided
if [ "$#" -ne 3 ]; then
    warning "Missing parameters."
    error "Usage: $0 <name_of_users> <number_of_users> <group_name>
    Example: $0 dev 5 developers"
fi

USER_PREFIX=$1 # Prefix for the new users (e.g., 'dev' creates dev1, dev2...)
NUM_USERS=$2
GROUP_NAME=$3
 
# Validate that NUM_USERS is a positive integer
if ! [[ "$NUM_USERS" =~ ^[0-9]+$ ]] || [ "$NUM_USERS" -lt 1 ]; then
    error "The first parameter must be an integer greater than 0."
fi

info "=== SETTING UP TEAM: $GROUP_NAME WITH $NUM_USERS NEW USERS ==="

# Create the group if it doesn't exist
if ! getent group "$GROUP_NAME" > /dev/null; then
    run_command groupadd "$GROUP_NAME"
    log "Group '$GROUP_NAME' created."
else
    info "Group '$GROUP_NAME' already exists. Users will be added to it."
fi

# Find the highest existing user number for the prefix to continue from there
# This extracts numbers from users matching the prefix (e.g., dev1, dev3) and gets the max
# sed "substitute/search/replace"
MAX_ID=$(getent passwd | cut -d: -f1 | grep "^${USER_PREFIX}[0-9]\+$" | sed "s/^${USER_PREFIX}//" | sort -n | tail -1)

if [ -z "$MAX_ID" ]; then
    START_ID=1
else
    START_ID=$((MAX_ID + 1))
fi

DEFAULT_PASS="password" # Default password for new users

# Create the users and add them to the group
for (( i=0; i<NUM_USERS; i++ )); do
    CURRENT_ID=$((START_ID + i))
    NEW_USER="${USER_PREFIX}${CURRENT_ID}"
    log "Creating user $NEW_USER..."
    
    # -m creates home, -s sets shell, -G adds to group
    run_command useradd -m -s /bin/bash -G "$GROUP_NAME" "$NEW_USER"
    # Set default password
    echo "$NEW_USER:$DEFAULT_PASS" | chpasswd
done

success "$NUM_USERS new users created (starting from $USER_PREFIX$START_ID) and added to '$GROUP_NAME'."

# Create the shared directory for the team
BASE_DIR="/home/${GROUP_NAME}"
info "Configuring shared directory at $BASE_DIR..."

if [ ! -d "$BASE_DIR" ]; then
    run_command mkdir -p "$BASE_DIR"
fi

# Assign ownership to root and the team group
run_command chown root:"$GROUP_NAME" "$BASE_DIR"

# Apply special permissions (SGID and Sticky Bit)
# 3 = Sticky Bit (1) + SGID (2)
# 7 = root (rwx)
# 7 = group (rwx)
# 0 = others (no access)
run_command chmod 3770 "$BASE_DIR"

success "Shared directory $BASE_DIR successfully configured with SGID and Sticky Bit."
