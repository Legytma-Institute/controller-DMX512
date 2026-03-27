#!/usr/bin/env bash

#
# Print error message to stderr
#
function error() {
    echo -e "\033[31m$*\033[0m" >&2
}

export -f error
