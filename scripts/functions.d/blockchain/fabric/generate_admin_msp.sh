#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate_user_msp.sh"

#
# Generate Admin msp
#
function generate_admin_msp() {
    local PROVISIONER_NAME
    local PROVISIONER_PASSWORD
    local DOMAIN
    local TYPE_PATH

    PROVISIONER_NAME=$1
    PROVISIONER_PASSWORD=$2
    DOMAIN=$3
    TYPE_PATH=$4

    generate_user_msp "${PROVISIONER_NAME}" "${PROVISIONER_PASSWORD}" "${DOMAIN}" Admin "${TYPE_PATH}"
}

export -f generate_admin_msp
