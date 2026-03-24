#!/usr/bin/env bash

function generate_batch_install_ca() {
    local DOMAIN=$1
    local DOMAIN_DOCKER=$2
    local CURRENT_FILE_PATH=$3

    local FILE_NAME=$(basename ${CURRENT_FILE_PATH})
    local TEMP_FILE_PATH=/tmp/${FILE_NAME}

    echo "@echo off" > ${TEMP_FILE_PATH}
    echo "" >> ${TEMP_FILE_PATH}
    echo "step >nul 2>&1 || (" >> ${TEMP_FILE_PATH}
    echo "    echo "Installing step cli..."" >> ${TEMP_FILE_PATH}
    echo "    winget install Smallstep.step" >> ${TEMP_FILE_PATH}
    echo ")" >> ${TEMP_FILE_PATH}
    echo "" >> ${TEMP_FILE_PATH}
    echo "if exist \"%tmp%\\${DOMAIN}_root_ca.crt\" (" >> ${TEMP_FILE_PATH}
    echo "    step certificate uninstall --all \"%tmp%\\${DOMAIN}_root_ca.crt\"" >> ${TEMP_FILE_PATH}
    echo ")" >> ${TEMP_FILE_PATH}
    echo "" >> ${TEMP_FILE_PATH}
    echo "step ca root \"%tmp%\\${DOMAIN}_root_ca.crt\" --force --ca-url \"https://ca.${DOMAIN_DOCKER}\" --fingerprint \"$(cat ${SOURCE_BASE_PATH}/.ca_fingerprint)\"" >> ${TEMP_FILE_PATH}
    echo "step certificate install --all \"%tmp%\\${DOMAIN}_root_ca.crt\"" >> ${TEMP_FILE_PATH}

    if [ ! -f "${CURRENT_FILE_PATH}" ] || [ "$(cat ${CURRENT_FILE_PATH})" != "$(cat ${TEMP_FILE_PATH})" ]; then
       sudo mv ${TEMP_FILE_PATH} ${CURRENT_FILE_PATH}
    fi
}

export -f generate_batch_install_ca
