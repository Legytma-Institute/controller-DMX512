#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../logging/stderr/error.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../logging/stdout/info.sh"

#
# Assign admin certificate to the domain msp
#
function assign_domain_admin_certificate() {
    local DOMAIN
    local TYPE_PATH
    local USER_NAME
    local DOMAIN_PATH
    local ADMIN_NAME
    local ADMIN_CERTIFICATE_PATH
    local MSP_DIR

    DOMAIN=$1
    TYPE_PATH=$2
    USER_NAME=$3

    # Set defaults if not provided
    if [ -z "${TYPE_PATH}" ]; then
        TYPE_PATH="peer"
    fi

    if [ -z "${USER_NAME}" ]; then
        USER_NAME="Admin"
    fi

    DOMAIN_PATH="${CERTS_DIR}/${TYPE_PATH}Organizations/vpn.${DOMAIN}"
    ADMIN_NAME="${USER_NAME}@vpn.${DOMAIN}"
    ADMIN_CERTIFICATE_PATH="${DOMAIN_PATH}/users/${ADMIN_NAME}/tls/client.crt"

    # Check if admin certificate exists
    if [ ! -f "${ADMIN_CERTIFICATE_PATH}" ]; then
        error "Admin certificate not found for ${ADMIN_NAME} in ${ADMIN_CERTIFICATE_PATH}"
        return 1
    fi

    info "Using admin certificate: ${ADMIN_CERTIFICATE_PATH}"

    # Copy admin certificate to all MSP directories
    while IFS= read -r -d '' MSP_DIR; do
        local ADMIN_CERTS_DIR="${MSP_DIR}/admincerts"
        local TARGET_CERT="${ADMIN_CERTS_DIR}/${ADMIN_NAME}.crt"

        # Create admincerts directory if it doesn't exist
        mkdir -p "${ADMIN_CERTS_DIR}"

        # Copy the certificate
        if cp "${ADMIN_CERTIFICATE_PATH}" "${TARGET_CERT}"; then
            info "Assigned admin certificate to ${TARGET_CERT}"
        else
            error "Failed to assign admin certificate to ${TARGET_CERT}"
        fi
    done < <(find "${CERTS_DIR}"/*Organizations/vpn."${DOMAIN}" -type d -name "msp" -print0 | grep -v "/users/")
}

export -f assign_domain_admin_certificate
