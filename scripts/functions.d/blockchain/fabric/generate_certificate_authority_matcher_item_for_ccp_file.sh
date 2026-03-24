#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../configuration/format/get_value_from_json_or_yaml.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate_matcher_item_for_ccp_file.sh"

#
# Generate a certificate authority matcher item for a ccp file
#
function generate_certificate_authority_matcher_item_for_ccp_file() {
    local PROFILE_ID
    local FABLO_TARGET_DIR
    local CONNECTION_PROFILE_FILE
    local ORGANIZATION
    local CERTIFICATE_AUTHORITIES
    local CERTIFICATE_AUTHORITY
    local CA_SERVER_CONFIG
    local CA_PORT

    PROFILE_ID=$1

    FABLO_TARGET_DIR="${CURRENT_DIR}/fablo-target"
    CONNECTION_PROFILE_FILE="${FABLO_TARGET_DIR}/fabric-config/connection-profiles/connection-profile-${PROFILE_ID}.yaml"

    # Get the organization from the connection profile
    ORGANIZATION=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".client.organization")
    CERTIFICATE_AUTHORITIES=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".organizations.${ORGANIZATION}.certificateAuthorities[]")

    for CERTIFICATE_AUTHORITY in ${CERTIFICATE_AUTHORITIES}; do
        CA_SERVER_CONFIG="${FABLO_TARGET_DIR}/fabric-config/fabric-ca-server-config/${CERTIFICATE_AUTHORITY/#ca\./}/fabric-ca-server-config.yaml"
        CA_PORT="$(get_value_from_json_or_yaml "${CA_SERVER_CONFIG}" ".port")"

        generate_matcher_item_for_ccp_file "https://${CERTIFICATE_AUTHORITY}:${CA_PORT}"
    done
}

export -f generate_certificate_authority_matcher_item_for_ccp_file
