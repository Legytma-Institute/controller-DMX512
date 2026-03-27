#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../shell/logging/debug.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install_packages.sh"

#
# Install step cli
#
function install_step_cli() {
    if [ -z "$(command -v step)" ]; then
        debug "Installing step cli..."

        install_packages wget

        wget -O /tmp/step-cli_amd64.deb https://dl.smallstep.com/cli/docs-cli-install/latest/step-cli_amd64.deb

        sudo dpkg -i /tmp/step-cli_amd64.deb
        rm -rf /tmp/step-cli_amd64.deb
    fi
}

export -f install_step_cli
