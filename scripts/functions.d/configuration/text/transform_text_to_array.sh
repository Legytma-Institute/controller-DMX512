#!/usr/bin/env bash

#
# Transform a text to a array
#
function transform_text_to_array() {
    local TEXT
    local SEPARATOR

    TEXT=$1
    SEPARATOR=$2

    # Transform the text to a array splitting by separator preserving spaces
    echo "${TEXT}" | tr "${SEPARATOR}" '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

export -f transform_text_to_array
