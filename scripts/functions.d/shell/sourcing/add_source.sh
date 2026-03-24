#!/usr/bin/env bash

#
# Add source to file
#
function add_source() {
    local FUNCTION_SOURCE
    local FILES
    local FILE

    FUNCTION_SOURCE=$1

    shift 1

    FILES=("$@")

    # If array size is 0, set default files
    if [ ${#FILES[@]} -eq 0 ]; then
        FILES=("${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.bash_profile" "${HOME}/.profile")
    fi

    for FILE in "${FILES[@]}"; do
        if [ -f "${FILE}" ]; then
            if ! grep -q "source ${FUNCTION_SOURCE}" "${FILE}"; then
                echo "source ${FUNCTION_SOURCE}" >> "${FILE}"
            fi
        fi
    done
}

export -f add_source
