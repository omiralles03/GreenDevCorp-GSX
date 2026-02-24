#!/bin/bash
set -euo pipefail #Exit on error

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


#Las comprovaciones de instalacion se hacen antes
#lgo todo esto se quita es para acordarme de pq pongo las cosas
#sed [ops] 'comd' file
#dentro de 'comd': la opcion s (sustitucion): 's/buscar/sustituir/'
#flag -i para escribir en el archivo

# SSH Configuration

info "Applying SSH security configuration in /etc/ssh/sshd_config..."

sudo sed -Ei 's/^#?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -Ei 's/^#?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -Ei 's/^#?ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
sudo sed -Ei 's/^#?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -Ei 's/^#?ClientAliveCountMax.*/ClientAliveCountMax 0/' /etc/ssh/sshd_config

#comprobamos gramatica y reiniciamos
sudo sshd -t
info "Syntax correct, restarting SSH..."
sudo systemctl restart ssh
info "SSH configuration completed successfully."
