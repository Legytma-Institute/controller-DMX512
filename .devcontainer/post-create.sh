#!/usr/bin/env bash

set -e

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Make scripts executable
sudo chmod -R +x "${THIS_DIR}"/../scripts/*.sh

if [ ! -f "${THIS_DIR}/../scripts/functions.sh" ]; then
    rm -rf /tmp/bash-lib
    git clone --depth=1 git@github.com:Legytma/bash-lib.git /tmp/bash-lib
    bash /tmp/bash-lib/setup.sh
    rm -rf /tmp/bash-lib
fi

# shellcheck source=../scripts/functions.sh
source "${THIS_DIR}"/../scripts/functions.sh

# Configure current directory as safe directory
# shellcheck disable=SC2119
configure_git

# Add this alias and function source to .bashrc, .zshrc, .bash_profile, and .profile
# shellcheck disable=SC2119
add_this_alias_and_function_source

if [ "$1" == "--chown" ]; then
    sudo chown -Rv "$(id -u):$(id -g)" "${CURRENT_DIR}"
fi

pipx install uv

# Update and upgrade packages
sudo apt update
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y

pip install --upgrade pip

sudo apt install -y minicom screen setserial udev

# Criar grupo dialout se não existir
if ! sudo getent group dialout; then
    sudo groupadd dialout
fi

# Adicionar usuário ao grupo dialout
sudo usermod -a -G dialout $USER

# Configurar permissões para dispositivos seriais
sudo tee /etc/udev/rules.d/99-serial.rules << EOF
# Regras para dispositivos seriais
KERNEL=="ttyUSB[0-9]*", MODE="0666", GROUP="dialout"
KERNEL=="ttyACM[0-9]*", MODE="0666", GROUP="dialout"
KERNEL=="ttyS[0-9]*", MODE="0666", GROUP="dialout"
EOF

"${SCRIPT_DIR}/setup-serial.sh"

docker restart $(hostname)
