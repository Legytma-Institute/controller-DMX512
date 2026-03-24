#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../setup/installation/install_packages.sh"

#
# Load .env file
#
function load_env_file() {
    if [ -f "${CURRENT_DIR}/.env" ]; then
        install_packages direnv

        direnv dotenv > /tmp/.env.tmp

        # shellcheck source=/dev/null
        . /tmp/.env.tmp
    fi
}

export -f load_env_file
