#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install_step_cli.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../shell/logging/debug.sh"

#
# Install CA certificate for a given domain
#
function install_ca_certificate() {
    local DOMAIN
    local FINGERPRINT
    local ROOT_CA_PATH
    local STEP_CA_URL

    DOMAIN=$1
    FINGERPRINT=$2

    ROOT_CA_PATH="/usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt"
    STEP_CA_URL="https://ca.docker.vpn.${DOMAIN}"

    if [ ! -f "${ROOT_CA_PATH}" ]; then
        install_step_cli

        debug "Installing root CA certificate for ${DOMAIN}"
        sudo step ca root "${ROOT_CA_PATH}" --force --ca-url "${STEP_CA_URL}" --fingerprint "${FINGERPRINT}"
        sudo step certificate install --all "${ROOT_CA_PATH}"
        sudo chmod 644 "${ROOT_CA_PATH}"

        sudo update-ca-certificates
    fi
}

export -f install_ca_certificate
