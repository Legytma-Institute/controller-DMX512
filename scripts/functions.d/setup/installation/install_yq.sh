#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../misc/install_latest_version.sh"

#
# Install yq
#
function install_yq() {
    install_latest_version "mikefarah/yq" "yq_linux_amd64" "yq"
}

export -f install_yq
