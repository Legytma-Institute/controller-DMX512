#!/usr/bin/env bash

#
# Print warning message to stderr
#
function warning() {
    echo -e "\033[33m$*\033[0m" >&2
}

export -f warning
