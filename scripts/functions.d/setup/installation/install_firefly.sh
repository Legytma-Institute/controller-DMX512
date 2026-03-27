#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../shell/logging/debug.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install_packages.sh"

#
# Install firefly
#
function install_firefly() {
    if ! command -v ff &> /dev/null; then
        debug "Installing firefly..."

        install_packages go golang

        go install github.com/hyperledger/firefly-cli/ff@latest

        debug "firefly installed successfully"
    fi
}

export -f install_firefly
