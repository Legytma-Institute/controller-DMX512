#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../network/http/get_latest_version.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../shell/logging/debug.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install_latest_version.sh"

#
# Install upx
#
function install_upx() {
    local REPOSITORY
    local VERSION
    local CLEAN_VERSION

    if ! command -v "upx" &> /dev/null; then
        REPOSITORY="upx/upx"
        VERSION=$(get_latest_version "${REPOSITORY}")
         # Remove prefixo 'v' se existir (ex: v5.0.2 → 5.0.2)
        CLEAN_VERSION="${VERSION#v}"

        debug "Detected UPX version: ${VERSION} (cleaned: ${CLEAN_VERSION})"

        install_latest_version "${REPOSITORY}" "upx-${CLEAN_VERSION}-amd64_linux.tar.xz" upx
    fi
}

export -f install_upx
