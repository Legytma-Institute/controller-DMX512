#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../setup/installation/install_yq.sh"

#
# Replace field values in a yaml file
#
function replace_field_values_in_json_or_yaml() {
    local DESTINATION_FILE
    local FIELD_PATH
    local FIELD_VALUE
    local ESCAPE

    DESTINATION_FILE=$1
    FIELD_PATH=$2
    FIELD_VALUE=$3
    ESCAPE=$4

    if [ -z "${ESCAPE}" ]; then
        ESCAPE=true
    fi

    # Install yq if not available
    install_yq

    # Use yq for YAML manipulation
    if [ "${ESCAPE}" == true ]; then
        yq eval "${FIELD_PATH} = \"${FIELD_VALUE}\"" -i "${DESTINATION_FILE}"
    else
        yq eval "${FIELD_PATH} = ${FIELD_VALUE}" -i "${DESTINATION_FILE}"
    fi
}

export -f replace_field_values_in_json_or_yaml
