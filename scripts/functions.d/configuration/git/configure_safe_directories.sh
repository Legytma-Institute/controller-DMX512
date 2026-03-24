#!/usr/bin/env bash

#
# Configure current directory as safe directory
#
function configure_safe_directories() {
    local DIRECTORIES

    DIRECTORIES=("$@")

    # If array size is 0, set default directory
    if [ ${#DIRECTORIES[@]} -eq 0 ]; then
        DIRECTORIES=("${CURRENT_DIR}")
    fi

    for DIRECTORY in "${DIRECTORIES[@]}"; do
        git config --global --add safe.directory "${DIRECTORY}"
    done
}

export -f configure_safe_directories
