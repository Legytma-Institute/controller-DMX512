#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/add_alias.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/add_source.sh"

#
# Add this alias and function source to file
#
function add_this_alias_and_function_source() {
    add_alias "this" "${SCRIPT_DIR}/this.sh" "${@}"
    add_source "${SCRIPT_DIR}/functions.sh" "${@}"
}

export -f add_this_alias_and_function_source
