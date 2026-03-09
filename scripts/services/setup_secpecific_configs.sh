#!/bin/bash
. "/usr/local/lib/gsx-messages.sh"
set -e
export PATH=$PATH:/usr/bin:/usr/sbin:/bin:/sbin

#--- SPECIFIC CONFIGURATIONS FOR SHARED DIRECTORY ---

GROUP_NAME="greendevcorp"
BASE_DIR="/home/${GROUP_NAME}"
info "Configuring corporate directory structure at $BASE_DIR..."

# Carpeta 'shared' (SGID y Sticky Bit)

SHARED_DIR="$BASE_DIR/shared"
run_command mkdir -p "$SHARED_DIR"
run_command chown root:"$GROUP_NAME" "$SHARED_DIR"

# 3770: root(rwx), grupo(rwx), otros(---) + SGID + Sticky Bit
run_command chmod 3770 "$SHARED_DIR"
log "$SHARED_DIR configured (3770)."

# Carpeta 'bin' (Scripts ejecutables solo por el equipo)
BIN_DIR="$BASE_DIR/bin"
run_command mkdir -p "$BIN_DIR"
run_command chown root:"$GROUP_NAME" "$BIN_DIR"
# 0750: root(rwx), grupo(r-x), otros(---). 
# El grupo solo puede leer y ejecutar, NO escribir/borrar scripts.
run_command chmod 0750 "$BIN_DIR"
log "$BIN_DIR configured (0750)."

# Archivo 'done.log' (Legible por todos, escribible solo por dev1)
LOG_FILE="$BASE_DIR/done.log"
run_command touch "$LOG_FILE"
# Asignamos la propiedad del archivo al primer usuario creado (ej. dev1) y al grupo
AUTHORIZED_USER="dev1" 
run_command chown "$AUTHORIZED_USER":"$GROUP_NAME" "$LOG_FILE"

# 0644: dueño(rw-), grupo(r--), otros(r--).
# Solo dev1 puede escribir. Todos los demás solo pueden leer.
run_command chmod 0644 "$LOG_FILE"
log "$LOG_FILE configured (0644, owned by $AUTHORIZED_USER)."

success "Corporate environment in $BASE_DIR successfully set up!"