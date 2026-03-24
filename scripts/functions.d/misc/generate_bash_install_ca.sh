#!/usr/bin/env bash

function generate_bash_install_ca() {
    local DOMAIN=$1
    local DOMAIN_DOCKER=$2
    local CURRENT_FILE_PATH=$3

    local FILE_NAME=$(basename ${CURRENT_FILE_PATH})
    local TEMP_FILE_PATH=/tmp/${FILE_NAME}

    echo "#!/usr/bin/env bash" > ${TEMP_FILE_PATH}
    echo "" >> ${TEMP_FILE_PATH}
    echo "function installCa() {" >> ${TEMP_FILE_PATH}
    echo '    if [ -z "$(command -v step)" ]; then' >> ${TEMP_FILE_PATH}
    echo "        echo "Installing step cli..."" >> ${TEMP_FILE_PATH}
    echo "" >> ${TEMP_FILE_PATH}
    echo "        wget -O /tmp/step-cli_amd64.deb https://dl.smallstep.com/cli/docs-cli-install/latest/step-cli_amd64.deb" >> ${TEMP_FILE_PATH}
    echo "" >> ${TEMP_FILE_PATH}
    echo "        sudo dpkg -i /tmp/step-cli_amd64.deb" >> ${TEMP_FILE_PATH}
    echo "        rm -rf /tmp/step-cli_amd64.deb" >> ${TEMP_FILE_PATH}
    echo "    fi" >> ${TEMP_FILE_PATH}
    echo "" >> ${TEMP_FILE_PATH}
    echo "    if [ -f /usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt ]; then" >> ${TEMP_FILE_PATH}
    echo "        step certificate uninstall --all /usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt" >> ${TEMP_FILE_PATH}
    echo "    fi" >> ${TEMP_FILE_PATH}
    echo "" >> ${TEMP_FILE_PATH}
    echo "    step ca root /usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt --force --ca-url \"https://ca.${DOMAIN_DOCKER}\" --fingerprint \"$(cat ${SOURCE_BASE_PATH}/.ca_fingerprint)\"" >> ${TEMP_FILE_PATH}
    echo "    step certificate install --all /usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt" >> ${TEMP_FILE_PATH}
    echo "    chmod 644 /usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt" >> ${TEMP_FILE_PATH}
    echo "" >> ${TEMP_FILE_PATH}
    echo "    sudo update-ca-certificates" >> ${TEMP_FILE_PATH}
    echo "}" >> ${TEMP_FILE_PATH}
    echo "" >> ${TEMP_FILE_PATH}
    echo "export -f installCa" >> ${TEMP_FILE_PATH}
    echo "" >> ${TEMP_FILE_PATH}
    echo "installCa" >> ${TEMP_FILE_PATH}

    if [ ! -f "${CURRENT_FILE_PATH}" ] || [ "$(cat ${CURRENT_FILE_PATH})" != "$(cat ${TEMP_FILE_PATH})" ]; then
       sudo mv ${TEMP_FILE_PATH} ${CURRENT_FILE_PATH}

        chmod +x ${CURRENT_FILE_PATH}
        sudo ${CURRENT_FILE_PATH}
    fi
}

export -f generate_bash_install_ca
