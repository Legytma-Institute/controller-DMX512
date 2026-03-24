#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/execute_on_super.sh"

#
# Execute this script on super devcontainer
#
function super_this() {
    local SCRIPT_PATH

    SCRIPT_PATH=scripts/this.sh

    execute_on_super ${SCRIPT_PATH} "$@"
}

export -f super_this
