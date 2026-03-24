#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../logging/stdout/debug.sh"

#
# Generate a msp config file
#
function generate_msp_config() {
    local MSP_DIR
    local ORGANIZATION_UNIT_IDENTIFIERS
    local MSP_CONFIG_FILE

    MSP_DIR=$1
    shift 1
    ORGANIZATION_UNIT_IDENTIFIERS=("$@")

    debug "Generating MSP config for ${MSP_DIR}"

    MSP_CONFIG_FILE="${MSP_DIR}/config.yaml"

    # Remove existing config file
    rm -rf "${MSP_CONFIG_FILE}"

    # Create config.yaml starting with OrganizationalUnitIdentifiers if any OUs are provided
    if [ ${#ORGANIZATION_UNIT_IDENTIFIERS[@]} -gt 0 ]; then
        echo "OrganizationalUnitIdentifiers:" > "${MSP_CONFIG_FILE}"

        for OU in "${ORGANIZATION_UNIT_IDENTIFIERS[@]}"; do
            echo "  - Certificate: cacerts/ca-cert.pem" >> "${MSP_CONFIG_FILE}"
            echo "    OrganizationalUnitIdentifier: ${OU}" >> "${MSP_CONFIG_FILE}"
        done

        echo "" >> "${MSP_CONFIG_FILE}"
    fi

    # Add NodeOUs section
    cat >> "${MSP_CONFIG_FILE}" << EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca-cert.pem
    OrganizationalUnitIdentifier: Client
  PeerOUIdentifier:
    Certificate: intermediatecerts/intermediate-cert.pem
    OrganizationalUnitIdentifier: Peer
  AdminOUIdentifier:
    Certificate: intermediatecerts/intermediate-cert.pem
    OrganizationalUnitIdentifier: Admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca-cert.pem
    OrganizationalUnitIdentifier: Orderer
EOF
}

export -f generate_msp_config
