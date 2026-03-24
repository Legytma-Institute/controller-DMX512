#!/usr/bin/env bash

#
# Get a token for a given domain and provisioner
#
function get_provisioner_token() {
    local PROVISIONER_NAME
    local PROVISIONER_PASSWORD
    local DOMAIN
    local STEP_CA_URL
    local ROOT_CA_PATH

    PROVISIONER_NAME=$1
    PROVISIONER_PASSWORD=$2
    DOMAIN=$3

    STEP_CA_URL="https://ca.docker.vpn.${DOMAIN}"
    ROOT_CA_PATH="/usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt"

    >&2 echo "Getting token for ${PROVISIONER_NAME}@${DOMAIN}"

    step ca token --ca-url "${STEP_CA_URL}" --root "${ROOT_CA_PATH}" --provisioner "${PROVISIONER_NAME}" --password-file <(echo -n "${PROVISIONER_PASSWORD}") \
        "orderer0.vpn.${DOMAIN}"
}

export -f get_provisioner_token
