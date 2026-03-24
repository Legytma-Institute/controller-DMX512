#!/usr/bin/env bash

#
# Add alias to file
#
function add_alias() {
    local ALIAS_NAME
    local ALIAS_VALUE
    local FILES
    local FILE

    ALIAS_NAME=$1
    ALIAS_VALUE=$2

    shift 2

    FILES=("$@")

    # If array size is 0, set default files
    if [ ${#FILES[@]} -eq 0 ]; then
        FILES=("${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.bash_profile" "${HOME}/.profile")
    fi

    for FILE in "${FILES[@]}"; do
        if [ -f "${FILE}" ]; then
            if ! grep -q "alias ${ALIAS_NAME}='${ALIAS_VALUE}'" "${FILE}"; then
                echo "alias ${ALIAS_NAME}='${ALIAS_VALUE}'" >> "${FILE}"
            fi
        fi
    done
}

export -f add_alias
