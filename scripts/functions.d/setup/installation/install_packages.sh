#!/usr/bin/env bash

# source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../blockchain/fabric/generate_msp_config.sh"

# #
# # Generate a msp config file
# #
# function generate_msp_config() {
#     local MSP_DIR=$1

#     echo "Generating MSP config for ${MSP_DIR}"

#     # Create config.yaml with NodeOUs enabled
#     cat > "${MSP_DIR}/config.yaml" << EOF
# NodeOUs:
#   Enable: true
#   ClientOUIdentifier:
#     Certificate: cacerts/ca-cert.pem
#     OrganizationalUnitIdentifier: client
#   PeerOUIdentifier:
#     Certificate: cacerts/ca-cert.pem
#     OrganizationalUnitIdentifier: peer
#   AdminOUIdentifier:
#     Certificate: cacerts/ca-cert.pem
#     OrganizationalUnitIdentifier: admin
#   OrdererOUIdentifier:
#     Certificate: cacerts/ca-cert.pem
#     OrganizationalUnitIdentifier: orderer
# EOF
# }

# export -f generate_msp_config

#
# Install packages if a command is not found
#
function install_packages() {
    local COMMAND=$1
    shift 1

    local PACKAGES=$1

    if ! command -v $COMMAND &> /dev/null; then
        sudo apt update

        if [ -z "$PACKAGES" ]; then
            sudo apt install -y $COMMAND || exit 1
        else
            sudo apt install -y $@ || exit 1
        fi
    fi
}

export -f install_packages
