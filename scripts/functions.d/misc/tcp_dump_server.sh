#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../setup/installation/install_packages.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../shell/logging/info.sh"

function tcp_dump_server() {
    local PORT
    local RESPONSE_HOST
    local USER_NAME
    local PASSWORD

    PORT=$1
    RESPONSE_HOST=$2
    USER_NAME=$3
    PASSWORD=$4

    if [ -z "${PORT}" ]; then
        PORT=8080
    fi

    install_packages python3

    info "Iniciando TCP Dump Server na porta ${PORT}..."

    python3 ${SCRIPT_DIR}/tcp_dump_server.py "${PORT}" "${RESPONSE_HOST}" "${USER_NAME}" "${PASSWORD}"
}

export -f tcp_dump_server
