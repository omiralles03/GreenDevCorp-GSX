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


# ---- RESOURCE LIMITS (PAM) ----

info "Configuring resource limits for group $GROUP_NAME..."

LIMITS_FILE="/etc/security/limits.d/${GROUP_NAME}.conf"

# Crear archivo de límites para el grupo
# nproc: max processes | nofile: max open files | rss: max memory in KB | cpu: max CPU time in minutes
cat <<EOF | sudo tee "$LIMITS_FILE" >/dev/null
# Limits for the development team, when we put @groupname it applies to each user in that group

@${GROUP_NAME} soft nproc 600
@${GROUP_NAME} hard nproc 700

@${GROUP_NAME} soft nofile 2048
@${GROUP_NAME} hard nofile 4096

@${GROUP_NAME} soft rss 1024000
@${GROUP_NAME} hard rss 2048000

@${GROUP_NAME} soft cpu 10
@${GROUP_NAME} hard cpu 15
EOF

log "Resource limits applied via PAM in $LIMITS_FILE."

# ---- ENVIRONMENT PERSONALIZATION (/etc/profile.d/) ----


info "Setting up personalized environment for team members..."

PROFILE_FILE="/etc/profile.d/${GROUP_NAME}_env.sh"

# Crear script que se ejecuta cada vez que un usuario hace login
cat <<'EOF' | sudo tee "$PROFILE_FILE" >/dev/null
#!/bin/bash
# Apply only if the user is in the dev group
if id -nG "$USER" | grep -qw "greendevcorp"; then
    # Add shared bin directory to PATH
    export PATH="$PATH:/home/greendevcorp/bin"
    
    # Common team aliases
    alias shared="cd /home/greendevcorp/shared"
    alias dlog="cat /home/greendevcorp/done.log"
    
    # Visual cue in terminal
    export PROMPT_COMMAND='PS1="\[\e[38;5;28m\][DEV-TEAM]\[\e[36m\][\u]\[\e[m\] \w ~$ "'
fi
EOF

# Darle permisos de ejecución al profile
run_command chmod 755 "$PROFILE_FILE"

log "Shared environment configured in $PROFILE_FILE."




success "Corporate environment in $BASE_DIR successfully set up!"