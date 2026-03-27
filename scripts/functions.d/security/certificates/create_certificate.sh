#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../shell/logging/info.sh"

#
# Create a certificate for a given domain
#
function create_certificate() {
    local PROVISIONER_NAME
    local PROVISIONER_PASSWORD
    local DOMAIN
    local CERTIFICATE_NAME
    local CERTIFICATE_PATH
    local CERTIFICATE_KEY_PATH
    local DATA_FILE
    local STEP_CA_URL
    local ROOT_CA_PATH

    PROVISIONER_NAME=$1
    PROVISIONER_PASSWORD=$2
    DOMAIN=$3
    CERTIFICATE_NAME=$4
    CERTIFICATE_PATH=$5
    CERTIFICATE_KEY_PATH=$6
    DATA_FILE=$7

    STEP_CA_URL="https://ca.docker.vpn.${DOMAIN}"
    ROOT_CA_PATH="/usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt"

    info "Generating certificate ${CERTIFICATE_NAME}"

    step ca certificate --force --ca-url "${STEP_CA_URL}" --root "${ROOT_CA_PATH}" --provisioner "${PROVISIONER_NAME}" --password-file <(echo -n "${PROVISIONER_PASSWORD}") \
        "${CERTIFICATE_NAME}" "${CERTIFICATE_PATH}" "${CERTIFICATE_KEY_PATH}" --set-file "${DATA_FILE}" --not-before -86400s --not-after 8640h --san "${CERTIFICATE_NAME}"
        # --set isCA=false --set maxPathLen=0 --set 'keyUsage=["digitalSignature", "keyEncipherment"]' #--set organizationalUnit=${PROVISIONER_NAME}
}

export -f create_certificate
