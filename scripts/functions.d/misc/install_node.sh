#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../logging/stdout/debug.sh"

#
# Install node
#
function install_node() {
    if ! command -v node &> /dev/null; then
        debug "Installing node..."

        # Install Node.js LTS
        nvm install --lts

        debug "Node installed successfully"
    fi
}

export -f install_node
