#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/add_export.sh"

#
# Add export to shell configs
#
function add_export_to_shell_configs() {
    local EXPORT_VALUE
    local FILES
    local FILE

    EXPORT_VALUE=$1
    shift 1
    FILES=("$@")

    if [ ${#FILES[@]} -eq 0 ]; then
        FILES=("${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.bash_profile" "${HOME}/.profile")
    fi

    for FILE in "${FILES[@]}"; do
        add_export "${EXPORT_VALUE}" "${FILE}"
    done
}

export -f add_export_to_shell_configs
