#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate_msp.sh"

#
# Generate user msp
#
function generate_user_msp() {
    local PROVISIONER_NAME
    local PROVISIONER_PASSWORD
    local DOMAIN
    local NAME
    local TYPE_PATH

    PROVISIONER_NAME=$1
    PROVISIONER_PASSWORD=$2
    DOMAIN=$3
    NAME=$4
    TYPE_PATH=$5

    generate_msp "${PROVISIONER_NAME}" "${PROVISIONER_PASSWORD}" "${DOMAIN}" "${NAME}" user "${TYPE_PATH}"
}

export -f generate_user_msp
