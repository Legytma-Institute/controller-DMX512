#!/usr/bin/env bash

set -e

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../scripts/functions.sh
source "${THIS_DIR}"/../scripts/functions.sh

# Recarregar regras udev
if command -v udevadm >/dev/null 2>&1 && [ -e /run/udev/control ]; then
    sudo udevadm control --reload-rules
    sudo udevadm trigger
else
    echo "Aviso: udevd não está disponível neste ambiente (container). Pulando reload/trigger."
fi

echo "Configuração de portas seriais concluída!"
echo "Dispositivos disponíveis:"
ls -la /dev/ttyUSB[0-9]* 2>/dev/null || ls -la /dev/ttyACM[0-9]* 2>/dev/null || ls -la /dev/ttyS* 2>/dev/null || echo "Nenhum dispositivo serial encontrado"
