#!/usr/bin/env bash

#
# Print debug message to stdout
#
function debug() {
    echo -e "\033[34m$*\033[0m" >&2
}

export -f debug
