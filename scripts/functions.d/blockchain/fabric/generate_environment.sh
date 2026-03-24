#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../configuration/prompt/get_input.sh"

#
# Generate environment
#
function generate_environment() {
    local ENVIRONMENT_NAME
    local QUERY
    local DESTINATION_FILE
    local ADITIONAL_DEFAULT_VALUE
    # local CONTEXT_BASE_PATH
    # local DEFAULT_BASE_PATH
    # local SOURCE_BASE_PATH
    local SOURCE_NAME
    local DEFAULT_FILE
    local SOURCE_FILE
    local SOURCE_VALUE
    local VALUE
    local SAVE_VALUE

    ENVIRONMENT_NAME=$1
    QUERY=$2
    DESTINATION_FILE=$3
    ADITIONAL_DEFAULT_VALUE=$4
    SAVE_VALUE=$5

    # CONTEXT_BASE_PATH="${CONTEXT_BASE_PATH:-.contexts}"
    # DEFAULT_BASE_PATH="${CONTEXT_BASE_PATH}/.default"
    # SOURCE_BASE_PATH="${CONTEXT_BASE_PATH}/${CONTEXT_NAME}/env"

    # Source name is the environment name lowercased
    SOURCE_NAME=$(echo "${ENVIRONMENT_NAME}" | tr '[:upper:]' '[:lower:]')
    DEFAULT_FILE="${DEFAULT_BASE_PATH}/.${SOURCE_NAME}"
    SOURCE_FILE="${SOURCE_BASE_PATH}/.${SOURCE_NAME}"

    if [ ! -f "${DESTINATION_FILE}" ]; then
        touch "${DESTINATION_FILE}"
    fi

    SOURCE_VALUE=""
    VALUE=""

    # If SAVE_VALUE is source, set the source value
    if [ "${SAVE_VALUE}" == "source" ]; then
        # If SOURCE_FILE dont exists, create it with the value
        if [ ! -f "${SOURCE_FILE}" ]; then
            mkdir -p "${SOURCE_BASE_PATH}"
            echo "${ADITIONAL_DEFAULT_VALUE}" > "${SOURCE_FILE}" || exit 1
        fi

        # Unset ADITIONAL_DEFAULT_VALUE
        ADITIONAL_DEFAULT_VALUE=""
    fi

    if [ -f "${SOURCE_FILE}" ]; then
        SOURCE_VALUE=$(printf '%s' "$(sed -z 's/^\s*//' "${SOURCE_FILE}")")
    fi

    # If SAVE_VALUE is default, set the default value
    if [ "${SAVE_VALUE}" == "default" ]; then
        # If DEFAULT_FILE dont exists, create it with the value
        if [ ! -f "${DEFAULT_FILE}" ]; then
            mkdir -p "${DEFAULT_BASE_PATH}"
            echo "${ADITIONAL_DEFAULT_VALUE}" > "${DEFAULT_FILE}"
        fi

        # Unset ADITIONAL_DEFAULT_VALUE
        ADITIONAL_DEFAULT_VALUE=""
    fi

    if [ -f "${DEFAULT_FILE}" ]; then
        DEFAULT=$(printf '%s' "$(sed -z 's/^\s*//' "${DEFAULT_FILE}")")
    fi

    if [ -n "${ADITIONAL_DEFAULT_VALUE}" ]; then
        DEFAULT="${DEFAULT}${ADITIONAL_DEFAULT_VALUE}"
    fi

    if [ "$(< "${DESTINATION_FILE}" grep "${ENVIRONMENT_NAME}=")" == "" ]; then
        if [ -f "${SOURCE_FILE}" ]; then
            VALUE=${SOURCE_VALUE}
        else
            VALUE=$(get_input "${QUERY}" "${DEFAULT}")
        fi

        echo "${ENVIRONMENT_NAME}=${VALUE}" >> "${DESTINATION_FILE}"
    else
        VALUE=$(< "${DESTINATION_FILE}" grep "${ENVIRONMENT_NAME}=" | sed "s/^${ENVIRONMENT_NAME}=\(.*\$\)/\1/")

        if [ -f "${SOURCE_FILE}" ] && [ "${SOURCE_VALUE}" != "${VALUE}" ]; then
            sed -i -E "s|(^${ENVIRONMENT_NAME}=).*$|\1${SOURCE_VALUE}|gm;t" "${DESTINATION_FILE}"

            VALUE=${SOURCE_VALUE}
        fi
    fi

    echo "${VALUE}"
}

export -f generate_environment
