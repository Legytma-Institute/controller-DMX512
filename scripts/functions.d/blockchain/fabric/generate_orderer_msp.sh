#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate_msp.sh"

#
# Generate orderer msp
#
function generate_orderer_msp() {
    local PROVISIONER_NAME
    local PROVISIONER_PASSWORD
    local DOMAIN
    local NAME

    PROVISIONER_NAME=$1
    PROVISIONER_PASSWORD=$2
    DOMAIN=$3
    NAME=$4

    generate_msp "${PROVISIONER_NAME}" "${PROVISIONER_PASSWORD}" "${DOMAIN}" "${NAME}" orderer
}

export -f generate_orderer_msp
