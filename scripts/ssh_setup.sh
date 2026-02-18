#!/bin/bash
set -euo pipefail #Exit on error

#Las comprovaciones de instalacion se hacen antes
#lgo todo esto se quita es para acordarme de pq pongo las cosas
#sed [ops] 'comd' file
#dentro de 'comd': la opcion s (sustitucion): 's/buscar/sustituir/'
#flag -i para escribir en el archivo

echo "Aplicando configuracion de seguridad en /etc/ssh/sshd_config..."

sudo sed -Ei 's/^#?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -Ei 's/^#?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -Ei 's/^#?ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
sudo sed -Ei 's/^#?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -Ei 's/^#?ClientAliveCountMax.*/ClientAliveCountMax 0/' /etc/ssh/sshd_config

#comprobamos gramatica y reiniciamos

sudo sshd -t
echo "Sintaxis correcta, reiniciando SSH..."

sudo systemctl restart ssh
echo "Configuración completada con éxito."
