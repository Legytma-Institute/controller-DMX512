#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../configuration/format/get_value_from_json_or_yaml.sh"

#
# Generate a certificate authority item for a ccp file
#
function generate_certificate_authority_item_for_ccp_file() {
    local PROFILE_ID
    local FABLO_TARGET_DIR
    local CONNECTION_PROFILE_FILE
    local ORGANIZATION
    local CERTIFICATE_AUTHORITIES
    local CERTIFICATE_AUTHORITY
    local CA_SERVER_CONFIG
    local CA_PORT
    local ENROLL_ID
    local ENROLL_SECRET
    local CA_HOST

    PROFILE_ID=$1

    FABLO_TARGET_DIR="${CURRENT_DIR}/fablo-target"
    CONNECTION_PROFILE_FILE="${FABLO_TARGET_DIR}/fabric-config/connection-profiles/connection-profile-${PROFILE_ID}.yaml"

    # Get the organization from the connection profile
    ORGANIZATION=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".client.organization")
    CERTIFICATE_AUTHORITIES=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".organizations.${ORGANIZATION}.certificateAuthorities[]")

    for CERTIFICATE_AUTHORITY in ${CERTIFICATE_AUTHORITIES}; do
        CA_HOST="$(echo "${CERTIFICATE_AUTHORITY}" | cut -d'.' -f2-)"
        CA_SERVER_CONFIG="${FABLO_TARGET_DIR}/fabric-config/fabric-ca-server-config/${CA_HOST}/fabric-ca-server-config.yaml"
        CA_PORT="$(get_value_from_json_or_yaml "${CA_SERVER_CONFIG}" ".port")"
        ENROLL_ID="$(get_value_from_json_or_yaml "${CA_SERVER_CONFIG}" ".registry.identities[0].name")"
        ENROLL_SECRET="$(get_value_from_json_or_yaml "${CA_SERVER_CONFIG}" ".registry.identities[0].pass")"

        echo "  ${CERTIFICATE_AUTHORITY}:"
        echo "    tlsCACerts:"
        echo "      path: /etc/firefly/organizations/${CA_HOST}/ca/${CERTIFICATE_AUTHORITY}-cert.pem"
        # echo "      path: /etc/firefly/organizations/${CA_HOST}/tlsca/tls${CERTIFICATE_AUTHORITY}-cert.pem"
        echo "    url: https://${CERTIFICATE_AUTHORITY}:${CA_PORT}"
        # echo "    grpcOptions:"
        # echo "      ssl-target-name-override: ${CERTIFICATE_AUTHORITY}"
        echo "    registrar:"
        echo "      enrollId: ${ENROLL_ID}"
        echo "      enrollSecret: ${ENROLL_SECRET}"
        # echo "    httpOptions:"
        # echo "      verify: false"
    done
}

export -f generate_certificate_authority_item_for_ccp_file
