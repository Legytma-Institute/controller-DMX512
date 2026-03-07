#!/bin/bash

# Script para configurar acesso às portas seriais no dev container

echo "Configurando acesso às portas seriais..."

# Instalar ferramentas para comunicação serial
sudo apt update -y
sudo apt install -y minicom screen setserial udev
# sudo apt install -y libcppunit-dev libcppunit-1.15-0 uuid-dev pkg-config libncurses-dev libtool autoconf automake g++ libmicrohttpd-dev libmicrohttpd12t64 protobuf-compiler libprotobuf-lite32t64 libprotobuf-dev libprotoc-dev zlib1g-dev bison flex make libftdi-dev libftdi1 libusb-1.0-0-dev liblo-dev libavahi-client-dev # python-protobuf python-numpy

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

# Recarregar regras udev
sudo udevadm control --reload-rules
sudo udevadm trigger

echo "Configuração de portas seriais concluída!"
echo "Dispositivos disponíveis:"
ls -la /dev/ttyUSB* 2>/dev/null || ls -la /dev/ttyACM* 2>/dev/null || ls -la /dev/ttyS* 2>/dev/null || echo "Nenhum dispositivo serial encontrado"
