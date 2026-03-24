#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../configuration/format/get_value_from_json_or_yaml.sh"

#
# Generate a organization item for a ccp file
#
function generate_organization_item_for_ccp_file() {
    local PROFILE_ID
    local CONNECTION_PROFILE_FILE
    local ORGANIZATION
    local MSP_ID
    local CERTIFICATE_AUTHORITIES
    local CERTIFICATE_AUTHORITY
    local PEERS
    local PEER

    PROFILE_ID=$1

    FABLO_TARGET_DIR="${CURRENT_DIR}/fablo-target"
    CONNECTION_PROFILE_FILE="${FABLO_TARGET_DIR}/fabric-config/connection-profiles/connection-profile-${PROFILE_ID}.yaml"

    # Get the organization from the connection profile
    ORGANIZATION=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".client.organization")
    MSP_ID=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".organizations.${ORGANIZATION}.mspid")
    CERTIFICATE_AUTHORITIES=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".organizations.${ORGANIZATION}.certificateAuthorities[]")
    PEERS=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".organizations.${ORGANIZATION}.peers[] | select(. | contains(\"${PROFILE_ID}\"))")

    echo "  ${ORGANIZATION}:"
    echo "    certificateAuthorities:"

    for CERTIFICATE_AUTHORITY in ${CERTIFICATE_AUTHORITIES}; do
        echo "      - ${CERTIFICATE_AUTHORITY}"
    done

    echo "    cryptoPath: /tmp/${ORGANIZATION}/msp"
    echo "    mspid: ${MSP_ID}"
    echo "    peers:"

    for PEER in ${PEERS}; do
        echo "      - ${PEER}"
    done
}

export -f generate_organization_item_for_ccp_file
