#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../misc/check_provisioner_exists.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../shell/logging/info.sh"

#
# Remove a provisioner
#
function remove_provisioner() {
    local PROVISIONER_NAME
    local DOMAIN
    local ADMIN_PROVISIONER_SUBJECT
    local ADMIN_PROVISIONER_NAME
    local ADMIN_PROVISIONER_PASSWORD
    local ROOT_PATH
    local CA_URL

    PROVISIONER_NAME=$1
    DOMAIN=$2
    ADMIN_PROVISIONER_SUBJECT=$3
    ADMIN_PROVISIONER_NAME=$4
    ADMIN_PROVISIONER_PASSWORD=$5

    if ! check_provisioner_exists "${PROVISIONER_NAME}" "${DOMAIN}"; then
        info "Provisioner ${PROVISIONER_NAME}@${DOMAIN} does not exist"
        return 0
    fi

    ROOT_PATH="/usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt"
    CA_URL="https://ca.docker.vpn.${DOMAIN}"

    info "Removing provisioner ${PROVISIONER_NAME}@${DOMAIN}"

    step ca provisioner remove "${PROVISIONER_NAME}" \
        --ca-url "${CA_URL}" \
        --root "${ROOT_PATH}" \
        --admin-subject "${ADMIN_PROVISIONER_SUBJECT}" \
        --admin-provisioner "${ADMIN_PROVISIONER_NAME}" \
        --admin-password-file <(echo -n "${ADMIN_PROVISIONER_PASSWORD}")
}

export -f remove_provisioner
