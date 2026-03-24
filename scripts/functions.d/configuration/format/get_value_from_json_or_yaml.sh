#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../setup/installation/install_yq.sh"

#
# Get a value from a json or yaml file
#
function get_value_from_json_or_yaml() {
    local SOURCE_FILE
    local FIELD_PATH

    SOURCE_FILE=$1
    FIELD_PATH=$2

    # Install yq
    install_yq

    # Get the value
    yq "${FIELD_PATH}" "${SOURCE_FILE}"
}

export -f get_value_from_json_or_yaml
