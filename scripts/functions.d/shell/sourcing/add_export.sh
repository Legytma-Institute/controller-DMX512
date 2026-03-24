#!/usr/bin/env bash

#
# Add export to file
#
function add_export() {
    local EXPORT_VALUE
    local FILES
    local FILE

    EXPORT_VALUE=$1

    shift 1

    FILES=("$@")

    # If array size is 0, set default files
    if [ ${#FILES[@]} -eq 0 ]; then
        FILES=("${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.bash_profile" "${HOME}/.profile")
    fi

    for FILE in "${FILES[@]}"; do
        if [ -f "${FILE}" ]; then
            if ! grep -q "export ${EXPORT_VALUE}" "${FILE}"; then
                echo "export ${EXPORT_VALUE}" >> "${FILE}"
            fi
        fi
    done
}

export -f add_export
