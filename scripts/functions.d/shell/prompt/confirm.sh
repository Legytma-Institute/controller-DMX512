#!/usr/bin/env bash

#
# confirm action in green
#
function confirm() {
    read -p "\033[32m$1 (y/N):\033[0m " -n 1 -r
    echo
    if [[ ${REPLY} =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

export -f confirm
