#!/usr/bin/env bash

#
# List all provisioners
#
function list_provisioners() {
    local DOMAIN
    local CA_URL
    local ROOT_PATH

    DOMAIN=$1

    CA_URL="https://ca.docker.vpn.${DOMAIN}"
    ROOT_PATH="/usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt"

    step ca provisioner list --ca-url "${CA_URL}" --root "${ROOT_PATH}"
}

export -f list_provisioners
