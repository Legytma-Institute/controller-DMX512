#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../setup/installation/install_latest_version.sh"

#
# Install fablo
#
function install_fablo() {
    install_latest_version "hyperledger-labs/fablo" "fablo.sh" "fablo"
}

export -f install_fablo
