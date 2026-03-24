#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../logging/stdout/info.sh"

#
# Create a data file for a given domain
#
function create_data_file() {
    local DOMAIN
    local DATA_FILE_NAME
    local ORGANIZATIONAL_UNIT
    local KEY_USAGE
    local EXT_KEY_USAGE
    local IS_CA
    local MAX_PATH_LEN
    local DATA_FILE

    DOMAIN=$1
    DATA_FILE_NAME=$2
    ORGANIZATIONAL_UNIT=$3
    KEY_USAGE=$4
    EXT_KEY_USAGE=$5
    IS_CA=$6
    MAX_PATH_LEN=$7

    DATA_FILE="${TEMPLATES_DIR}/${DOMAIN}/${DATA_FILE_NAME}.json"

    if [ ! -f "${DATA_FILE}" ]; then
        info "Creating data file ${DATA_FILE_NAME}"

        # Create JSON object with non-empty values
        local JSON_PARTS=()
        [ -n "${ORGANIZATIONAL_UNIT}" ] && JSON_PARTS+=("\"organizationalUnit\": ${ORGANIZATIONAL_UNIT}")
        [ -n "${ORGANIZATIONAL_UNIT}" ] && [ "${ORGANIZATIONAL_UNIT}" == "\"Admin\"" ] && JSON_PARTS+=("\"principals\": ${ORGANIZATIONAL_UNIT}")
        [ -n "${IS_CA}" ] && JSON_PARTS+=("\"isCA\": ${IS_CA}")
        [ -n "${MAX_PATH_LEN}" ] && JSON_PARTS+=("\"maxPathLen\": ${MAX_PATH_LEN}")
        [ -n "${KEY_USAGE}" ] && JSON_PARTS+=("\"keyUsage\": ${KEY_USAGE}")
        [ -n "${EXT_KEY_USAGE}" ] && JSON_PARTS+=("\"extKeyUsage\": ${EXT_KEY_USAGE}")

        # Join parts with commas and wrap in braces
        echo "{$(printf '%s' "${JSON_PARTS[@]/#/, }" | sed 's/^, //')}" > "${DATA_FILE}"
    fi
}

export -f create_data_file
