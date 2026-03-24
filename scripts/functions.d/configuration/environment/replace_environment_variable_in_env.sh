#!/usr/bin/env bash

#
# Replace or add Environment Variable
#
function replace_environment_variable_in_env() {
    local VAR_NAME
    local VAR_VALUE
    local FILE

    VAR_NAME=$1
    VAR_VALUE=$2
    FILE=$3

    grep -q "^${VAR_NAME}=" "${FILE}" && sed -i "s|^${VAR_NAME}=.*|${VAR_NAME}=${VAR_VALUE}|" "${FILE}" || echo "${VAR_NAME}=${VAR_VALUE}" >> "${FILE}"
}

export -f replace_environment_variable_in_env
