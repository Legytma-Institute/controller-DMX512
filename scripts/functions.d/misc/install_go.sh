#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../logging/stdout/debug.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../setup/installation/install_packages.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../shell/sourcing/add_export.sh"

#
# Install GO
#
function install_go() {
    local GO_VERSION

    GO_VERSION=$1

    if ! command -v go &> /dev/null; then
        debug "Installing Go..."

        install_packages curl

        if [ -z "${GO_VERSION}" ]; then
            GO_VERSION="1.25.6"
        fi

        curl -L -o /tmp/go.linux-amd64.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"

        sudo rm -rf /usr/local/go

        sudo tar -C /usr/local -xzf /tmp/go.linux-amd64.tar.gz

        rm -rf /tmp/go.linux-amd64.tar.gz

        add_export "PATH=\"/usr/local/go/bin:\${PATH}\""

        export PATH="/usr/local/go/bin:${PATH}"

        go version

        debug "Go installed successfully"
    fi
}

export -f install_go
