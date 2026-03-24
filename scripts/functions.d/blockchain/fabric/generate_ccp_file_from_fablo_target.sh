#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../configuration/format/get_value_from_json_or_yaml.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate_certificate_authority_item_for_ccp_file.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate_channel_item_for_ccp_file.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../logging/stdout/debug.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate_organization_item_for_ccp_file.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../configuration/environment/get_environment_variable_from_docker_compose_file.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate_matcher_item_for_ccp_file.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate_certificate_authority_matcher_item_for_ccp_file.sh"

#
# Generate a ccp file for a given domain
#
function generate_ccp_file_from_fablo_target() {
    local PROFILE_ID
    local ADITIONAL_PROFILE_ID
    local FABLO_TARGET_DIR
    local FABLO_CONFIG_FILE
    local CONNECTION_PROFILE_FILE
    local CONFIGTX_FILE
    local DOCKER_COMPOSE_FILE
    local CHANNEL_NAMES
    local CHANNEL_NAME
    local CCP_FILE
    local ORGANIZATION
    local PEERS
    local PEER
    local CORE_PEER_ADDRESS
    local ORDERERS
    local ORDERER
    local ORDERER_HOST
    local CA_HOST

    PROFILE_ID=$1
    ADITIONAL_PROFILE_ID=$2

    FIREFLY_HOME="${FIREFLY_HOME:-${CURRENT_DIR:-${HOME}}/.firefly}"
    CCP_FILE="${FIREFLY_HOME}/${PROFILE_ID}-ccp.yaml"

    FABLO_TARGET_DIR="${CURRENT_DIR}/fablo-target"
    FABLO_CONFIG_FILE="${CURRENT_DIR}/fablo-config.yaml"
    CONNECTION_PROFILE_FILE="${FABLO_TARGET_DIR}/fabric-config/connection-profiles/connection-profile-${PROFILE_ID}.yaml"
    CONFIGTX_FILE="${FABLO_TARGET_DIR}/fabric-config/configtx.yaml"
    DOCKER_COMPOSE_FILE="${FABLO_TARGET_DIR}/fabric-docker/docker-compose.yaml"

    # Get the channel names from the fablo config file
    CHANNEL_NAMES=$(get_value_from_json_or_yaml "${FABLO_CONFIG_FILE}" ".channels[].name")

    # Get the organization from the connection profile
    ORGANIZATION=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".client.organization")
    PEERS=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".organizations.${ORGANIZATION}.peers[]")
    ADDITIONAL_PEERS=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".organizations.${ADITIONAL_PROFILE_ID}.peers[]")
    PEERS_ALL="${PEERS} ${ADDITIONAL_PEERS}"

    # Get the orderers from the configtx file
    # ORDERERS=$(get_value_from_json_or_yaml "${CONFIGTX_FILE}" ".Orderer.Addresses[] | select(. | contains(\"${PROFILE_ID}\"))")
    # ORDERERS=$(get_value_from_json_or_yaml "${CONFIGTX_FILE}" ".Orderers[].EtcdRaft.Consenters[].Host | select(. | contains(\"${PROFILE_ID}\"))")
    ORDERERS=$(get_value_from_json_or_yaml "${CONFIGTX_FILE}" ".Orderer.EtcdRaft.Consenters[] | \"\(.Host):\(.Port)\"")

    {
        echo "certificateAuthorities:"

        generate_certificate_authority_item_for_ccp_file "${PROFILE_ID}"
        generate_certificate_authority_item_for_ccp_file "${ADITIONAL_PROFILE_ID}"

        echo "channels:"

        for CHANNEL_NAME in ${CHANNEL_NAMES}; do
            # Skip if the channel name not contains the profile id
            if ! echo "${CHANNEL_NAME}" | grep -q "${PROFILE_ID}"; then
                continue
            fi

            generate_channel_item_for_ccp_file "${CHANNEL_NAME}"
        done

        echo "client:"
        echo "  BCCSP:"
        echo "    security:"
        echo "      default:"
        echo "        provider: SW"
        echo "      enabled: true"
        echo "      hashAlgorithm: SHA2"
        echo "      level: 256"
        echo "      softVerify: true"
        echo "  credentialStore:"
        echo "    cryptoStore:"
        echo "      path: /etc/firefly/organizations/fabric.vpn.${PROFILE_ID}.com.br/users"
        echo "    path: /etc/firefly/organizations/fabric.vpn.${PROFILE_ID}.com.br/users"
        echo "  cryptoconfig:"
        echo "    path: /etc/firefly/organizations/fabric.vpn.${PROFILE_ID}.com.br/msp"
        echo "  logging:"
        echo "    level: debug"
        echo "  organization: ${ORGANIZATION}"
        echo "  tlsCerts:"
        echo "    client:"
        echo "      cert:"
        echo "        path: /etc/firefly/organizations/fabric.vpn.${PROFILE_ID}.com.br/users/Admin@fabric.vpn.${PROFILE_ID}.com.br/msp/signcerts/Admin@fabric.vpn.${PROFILE_ID}.com.br-cert.pem"
        echo "      key:"
        echo "        path: /etc/firefly/organizations/fabric.vpn.${PROFILE_ID}.com.br/users/Admin@fabric.vpn.${PROFILE_ID}.com.br/msp/keystore/priv-key.pem"
        echo "orderers:"

        for ORDERER in ${ORDERERS}; do
            # # Skip if the orderer does not contain the profile id
            # if ! echo "${ORDERER}" | grep -q "${PROFILE_ID}"; then
            #     continue
            # fi

            ORDERER_HOST=$(echo "${ORDERER}" | cut -d':' -f1)
            # Remove the first part of the host
            CA_HOST=$(echo "${ORDERER_HOST}" | cut -d'.' -f3-)

            echo "  ${ORDERER_HOST}:"
            echo "    tlsCACerts:"
            echo "      path: /etc/firefly/organizations/${CA_HOST}/peers/${ORDERER_HOST}/msp/tlscacerts/tlsca.${CA_HOST}-cert.pem"
            echo "    url: grpcs://${ORDERER}"
        done

        echo "organizations:"

        generate_organization_item_for_ccp_file "${PROFILE_ID}"
        generate_organization_item_for_ccp_file "${ADITIONAL_PROFILE_ID}"

        echo "peers:"

        for PEER in ${PEERS_ALL}; do
            # Skip if the peer does not contain the profile id or additional profile
            if ! echo "${PEER}" | grep -Eq "${PROFILE_ID}|${ADITIONAL_PROFILE_ID}"; then
                continue
            fi

            CORE_PEER_ADDRESS=$(get_environment_variable_from_docker_compose_file "${DOCKER_COMPOSE_FILE}" "${PEER}" "CORE_PEER_ADDRESS")
            CA_HOST=$(echo "${PEER}" | cut -d'.' -f2-)

            echo "  ${PEER}:"
            echo "    tlsCACerts:"
            echo "      path: /etc/firefly/organizations/${CA_HOST}/peers/${PEER}/tls/ca.crt"
            echo "    url: grpcs://${CORE_PEER_ADDRESS}"
        done

        echo "version: 1.1.0%"
        echo ""
        echo "entityMatchers:"
        echo "  peer:"

        for PEER in ${PEERS_ALL}; do
            # Skip if the peer does not contain the profile id or additional profile
            if ! echo "${PEER}" | grep -Eq "${PROFILE_ID}|${ADITIONAL_PROFILE_ID}"; then
                continue
            fi

            CORE_PEER_ADDRESS=$(get_environment_variable_from_docker_compose_file "${DOCKER_COMPOSE_FILE}" "${PEER}" "CORE_PEER_ADDRESS")

            generate_matcher_item_for_ccp_file "${CORE_PEER_ADDRESS}"
        done

        echo "  orderer:"

        for ORDERER in ${ORDERERS}; do
            generate_matcher_item_for_ccp_file "${ORDERER}"
        done

        echo "  certificateAuthority:"

        generate_certificate_authority_matcher_item_for_ccp_file "${PROFILE_ID}"
        generate_certificate_authority_matcher_item_for_ccp_file "${ADITIONAL_PROFILE_ID}"
    } > "${CCP_FILE}"
}

export -f generate_ccp_file_from_fablo_target
