#!/usr/bin/env bash

#
# Generate a matcher item for a ccp file
#
function generate_matcher_item_for_ccp_file() {
    local ADDRESS
    local HOST

    ADDRESS=$1

    HOST=$(echo "${ADDRESS}" | sed 's|^[^:]*://||' | cut -d':' -f1)

    echo "    - pattern: ${HOST}"
    echo "      urlSubstitutionExp: ${ADDRESS}"
    echo "      sslTargetOverrideUrlSubstitutionExp: ${HOST}"
    echo "      mappedHost: ${HOST}"
}

export -f generate_matcher_item_for_ccp_file
