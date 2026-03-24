#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../configuration/format/get_value_from_json_or_yaml.sh"

#
# Generate a channel item for a ccp file
#
function generate_channel_item_for_ccp_file() {
    local CHANNEL_NAME
    local CHANNEL_PROFILE_IDS
    local CHANNEL_PROFILE_ID
    local EXECUTE
    local FABLO_TARGET_DIR
    local CONNECTION_PROFILE_FILE
    local CONFIGTX_FILE
    local ORGANIZATION
    local PEERS
    local PEER
    local ORDERERS
    local ORDERER

    CHANNEL_NAME=$1

    FABLO_TARGET_DIR="${CURRENT_DIR}/fablo-target"
    CONFIGTX_FILE="${FABLO_TARGET_DIR}/fabric-config/configtx.yaml"

    PEERS=()

    # Remove the the last part of the channel name and split by - and set the environment variable as an array
    CHANNEL_PROFILE_IDS=$(echo "${CHANNEL_NAME}" | cut -d'-' -f1- | tr '-' '\n')

    for CHANNEL_PROFILE_ID in ${CHANNEL_PROFILE_IDS}; do
        CONNECTION_PROFILE_FILE="${FABLO_TARGET_DIR}/fabric-config/connection-profiles/connection-profile-${PROFILE_ID}.yaml"

        # Get the organization from the connection profile
        ORGANIZATION=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".client.organization")

        # Add the peers to the array
        for PEER in $(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".organizations.${ORGANIZATION}.peers[]"); do
            # Add only if the peer is not already in the array
            if ! echo "${PEERS[@]}" | grep -q "${PEER}"; then
                PEERS+=("${PEER}")
            fi
        done
    done

    # Get the orderers (hosts) from the configtx file
    ORDERERS=$(get_value_from_json_or_yaml "${CONFIGTX_FILE}" ".Orderer.EtcdRaft.Consenters[].Host")

    echo "  ${CHANNEL_NAME}:"
    echo "    orderers:"

    for ORDERER in ${ORDERERS}; do
        EXECUTE=false

        for CHANNEL_PROFILE_ID in ${CHANNEL_PROFILE_IDS}; do
            if echo "${ORDERER}" | grep "${CHANNEL_PROFILE_ID}" > /dev/null; then
                EXECUTE=true
                break
            fi
        done

        if [ "${EXECUTE}" == false ]; then
            continue
        fi

        echo "      - ${ORDERER}"
    done

    echo "    peers:"

    for PEER in "${PEERS[@]}"; do
        EXECUTE=false

        for CHANNEL_PROFILE_ID in ${CHANNEL_PROFILE_IDS}; do
            if echo "${PEER}" | grep "${CHANNEL_PROFILE_ID}" > /dev/null; then
                EXECUTE=true
                break
            fi
        done

        # Skip if the peer does not contain the profile id
        if [ "${EXECUTE}" == false ]; then
            continue
        fi

        echo "      ${PEER}:"
        echo "        chaincodeQuery: true"
        echo "        endorsingPeer: true"
        echo "        eventSource: true"
        echo "        ledgerQuery: true"
    done
}

export -f generate_channel_item_for_ccp_file
