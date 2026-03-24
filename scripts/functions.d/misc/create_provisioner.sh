#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/check_provisioner_exists.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../logging/stdout/info.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../logging/stderr/error.sh"

#
# Create a new provisioner
#
function create_provisioner() {
    local PROVISIONER_NAME
    local PROVISIONER_PASSWORD
    local DOMAIN
    local ADMIN_PROVISIONER_SUBJECT
    local ADMIN_PROVISIONER_NAME
    local ADMIN_PROVISIONER_PASSWORD
    local PROVISIONER_TEMPLATE_FILE
    local ROOT_PATH
    local CA_URL
    local PROVISIONER_CREATE_RESULT

    PROVISIONER_NAME=$1
    PROVISIONER_PASSWORD=$2
    DOMAIN=$3
    ADMIN_PROVISIONER_SUBJECT=$4
    ADMIN_PROVISIONER_NAME=$5
    ADMIN_PROVISIONER_PASSWORD=$6

    if check_provisioner_exists "${PROVISIONER_NAME}" "${DOMAIN}"; then
        info "Provisioner ${PROVISIONER_NAME}@${DOMAIN} already exists"
        return 0
    fi

    PROVISIONER_TEMPLATE_FILE="${TEMPLATES_DIR}/${DOMAIN}/certificate.tpl"
    ROOT_PATH="/usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt"
    CA_URL="https://ca.docker.vpn.${DOMAIN}"

    info "Creating provisioner ${PROVISIONER_NAME}@${DOMAIN}"

    step ca provisioner add "${PROVISIONER_NAME}" --type JWK \
        --ca-url "${CA_URL}" \
        --root "${ROOT_PATH}" \
        --admin-subject "${ADMIN_PROVISIONER_SUBJECT}" \
        --admin-provisioner "${ADMIN_PROVISIONER_NAME}" \
        --admin-password-file <(echo -n "${ADMIN_PROVISIONER_PASSWORD}") \
        --x509-template "${PROVISIONER_TEMPLATE_FILE}" \
        --x509-max-dur 43200h \
        --x509-default-dur 8640h \
        --create \
        --password-file <(echo -n "${PROVISIONER_PASSWORD}")

    PROVISIONER_CREATE_RESULT=$?

    if [ "${PROVISIONER_CREATE_RESULT}" -ne 0 ]; then
        error "error creating provisioner ${PROVISIONER_NAME}@${DOMAIN}: ${PROVISIONER_CREATE_RESULT}"
    else
        info "Provisioner ${PROVISIONER_NAME}@${DOMAIN} created successfully"
    fi
}

export -f create_provisioner
