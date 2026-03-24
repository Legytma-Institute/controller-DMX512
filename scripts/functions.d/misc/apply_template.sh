#!/usr/bin/env bash

function apply_template() {
    local TEMPLATE_FILE=$1
    local VARIABLES=$2
    local DESTINATION_FILE=$3
    local PERMISSIONS=$4

    local FILE_NAME=$(basename ${DESTINATION_FILE})
    local TEMP_FILE_PATH=/tmp/${FILE_NAME}

    cat "${TEMPLATE_FILE}" | envsubst "${VARIABLES}" > ${TEMP_FILE_PATH}

    if cmp --silent -- "${DESTINATION_FILE}" "${TEMP_FILE_PATH}"; then
        echo "${DESTINATION_FILE} was not changed! Skiping..."
    else
        echo "${DESTINATION_FILE} was changed! Updating..."

        sudo rm -rf ${DESTINATION_FILE}
        sudo mv ${TEMP_FILE_PATH} ${DESTINATION_FILE}
        sudo chown -R ${PERMISSIONS} ${DESTINATION_FILE}
    fi
}

export -f apply_template
