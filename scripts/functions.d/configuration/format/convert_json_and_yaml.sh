#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../setup/installation/install_yq.sh"

#
# Convert a file from json to yaml or vice versa
#
# Usage:
#   convert.sh <source_file>
#
# Example:
#   convert.sh fabric-ca-server-config.json
#
function convert_json_and_yaml() {
    local SOURCE_FILE
    local SOURCE_FILE_NAME
    local SOURCE_EXTENSION
    local DESTINATION_EXTENSION

    SOURCE_FILE=$1

    SOURCE_FILE_NAME=${SOURCE_FILE%.*}
    SOURCE_EXTENSION=${SOURCE_FILE##*.}

    # If source extension is json, destination extension is yaml
    # If source extension is yaml, destination extension is json
    if [ "${SOURCE_EXTENSION}" == "json" ]; then
        DESTINATION_EXTENSION="yaml"
    else
        DESTINATION_EXTENSION="json"
    fi

    # Install yq
    install_yq

    # Convert
    yq -o="${DESTINATION_EXTENSION}" "${SOURCE_FILE}" > "${SOURCE_FILE_NAME}.${DESTINATION_EXTENSION}"
}

export -f convert_json_and_yaml
