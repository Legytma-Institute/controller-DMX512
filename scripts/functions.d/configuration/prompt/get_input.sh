#!/usr/bin/env bash

#
# Get input with default value
#
function get_input() {
    local PROMPT
    local DEFAULT
    local PROMPT_DEFAULT
    local INPUT

    PROMPT=$1
    DEFAULT=$2
    PROMPT_DEFAULT=""
    INPUT=""

    if [ -n "${DEFAULT}" ]; then
        PROMPT_DEFAULT=" [${DEFAULT}]"
    fi

    read -rp "\033[32m${PROMPT}${PROMPT_DEFAULT}:\033[0m " INPUT

    if [ -z "${INPUT}" ]; then
        echo "${DEFAULT}"
    else
        echo "${INPUT}"
    fi
}

export -f get_input
