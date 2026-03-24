#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../setup/installation/install_packages.sh"

# #
# # Download a intermediate certificate for a given domain
# #
# function download_intermediate_certificate() {
#     local DOMAIN
#     local ROOT_CA_PATH
#     local INTERMEDIATE_CA_PATH
#     local INTERMEDIATE_CA_URL

#     DOMAIN=$1

#     ROOT_CA_PATH="/usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt"
#     INTERMEDIATE_CA_PATH="${CACHE_DIR}/${DOMAIN}/intermediates.pem"
#     INTERMEDIATE_CA_URL="https://ca.docker.vpn.${DOMAIN}/1.0/intermediates.pem"

#     if [ ! -f ${INTERMEDIATE_CA_PATH} ]; then
#         echo "Downloading intermediate CA certificate for ${DOMAIN}"
#         mkdir -p ${CACHE_DIR}/${DOMAIN}

#         install_packages wget

#         wget --ca-certificate=${ROOT_CA_PATH} -O ${INTERMEDIATE_CA_PATH} ${INTERMEDIATE_CA_URL}
#     fi
# }

# export -f download_intermediate_certificate

#
# Check if a provisioner exists
#
function check_provisioner_exists() {
    local PROVISIONER_NAME
    local DOMAIN
    local CA_URL
    local ROOT_PATH
    local PROVISIONER_LIST
    local PROVISIONER_RESULT

    PROVISIONER_NAME=$1
    DOMAIN=$2

    CA_URL="https://ca.docker.vpn.${DOMAIN}"
    ROOT_PATH="/usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt"

    PROVISIONER_LIST=$(step ca provisioner list --ca-url "${CA_URL}" --root "${ROOT_PATH}")

    install_packages jq

    # Get the list of provisioners, return only the name of the provisioners and filter by the PROVISIONER_NAME
    PROVISIONER_RESULT=$(echo "${PROVISIONER_LIST}" | jq -r '.[] | .name' | grep "${PROVISIONER_NAME}")

    if [ "${PROVISIONER_RESULT}" == "${PROVISIONER_NAME}" ]; then
        return 0
    else
        return 1
    fi
}

export -f check_provisioner_exists
