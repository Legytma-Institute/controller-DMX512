#!/usr/bin/env bash

#
# Print info message to stdout
#
function info() {
    echo -e "\033[32m$*\033[0m" >&2
}

export -f info
