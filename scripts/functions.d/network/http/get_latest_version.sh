#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../setup/installation/install_packages.sh"

#
# Get latest version of a given repository
#
function get_latest_version() {
    local REPOSITORY
    local VERSION
    local URL

    REPOSITORY=$1

    URL="https://github.com/${REPOSITORY}/releases/latest"

    install_packages curl

    VERSION=$(curl -sLf "${URL}" | grep -oP "/${REPOSITORY}/releases/tag/\K[^\"]+" | head -n1)

    echo "${VERSION}"
}

export -f get_latest_version
