#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../shell/logging/info.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../security/certificates/create_certificate.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate_msp_config.sh"

#
# Generate a msp folder for a given organization with the following subfolders:
# - admincerts
# - cacerts
# - intermediatecerts
# - tlscacerts
# - tls
# - tlsintermediatecerts
# - signcerts
# - keystore
# - config.yaml
#
function generate_msp() {
    local PROVISIONER_NAME
    local PROVISIONER_PASSWORD
    local DOMAIN
    local NAME
    local TYPE
    local TYPE_PATH
    local NAME_LOWER
    local PREFIX
    local SIDE
    local DATA_TYPE
    # local PREFIX_LOWER
    local DOMAIN_PATH
    local MSP_DOMAIN_PATH
    local ARTIFACTS_PATH
    local MSP_PATH
    local TLS_PATH
    local CACHE_DOMAIN_PATH
    local MSP_DOMAIN_CACHE_PATH
    local TLS_DOMAIN_CACHE_PATH
    local CERTIFICATE_NAME
    local CERTIFICATE_PATH
    local CERTIFICATE_KEY_PATH
    local DATA_PATH
    local DATA_FILE

    PROVISIONER_NAME=$1
    PROVISIONER_PASSWORD=$2
    DOMAIN=$3
    NAME=$4
    TYPE=$5
    TYPE_PATH=$6

    NAME_LOWER=$(< "${NAME}" tr '[:upper:]' '[:lower:]')
    PREFIX=${NAME_LOWER}.
    SIDE="server"
    DATA_TYPE=${TYPE}

    if [ "${TYPE}" == "user" ]; then
        PREFIX=${NAME}@
        SIDE="client"

        if [ "${NAME}" == "Admin" ]; then
            DATA_TYPE=${NAME}
        fi

        if [ -z "${TYPE_PATH}" ]; then
            TYPE_PATH="peer"
        fi
    fi

    if [ -z "${TYPE_PATH}" ]; then
        TYPE_PATH=${TYPE}
    fi

    # PREFIX_LOWER=$(< "${PREFIX}" tr '[:upper:]' '[:lower:]')
    DOMAIN_PATH="${CERTS_DIR}/${TYPE_PATH}Organizations/vpn.${DOMAIN}"
    MSP_DOMAIN_PATH="${DOMAIN_PATH}/msp"
    ARTIFACTS_PATH="${DOMAIN_PATH}/${TYPE}s/${PREFIX}vpn.${DOMAIN}"
    MSP_PATH="${ARTIFACTS_PATH}/msp"
    TLS_PATH="${ARTIFACTS_PATH}/tls"
    CACHE_DOMAIN_PATH="${CACHE_DIR}/${DOMAIN}"
    MSP_DOMAIN_CACHE_PATH="${CACHE_DOMAIN_PATH}/msp"
    TLS_DOMAIN_CACHE_PATH="${CACHE_DOMAIN_PATH}/tls"

    info "Generating ${NAME} MSP for ${DOMAIN} with type ${TYPE}"

    mkdir -p "${DOMAIN_PATH}"
    mkdir -p "${ARTIFACTS_PATH}"

    # Copy cache domain directory converting all simbolic links to real files
    if [ ! -d "${MSP_DOMAIN_PATH}" ]; then
        cp -L -r "${MSP_DOMAIN_CACHE_PATH}" "${DOMAIN_PATH}"
    fi

    if [ ! -d "${MSP_PATH}" ]; then
        cp -L -r "${CACHE_DOMAIN_PATH}"/* "${ARTIFACTS_PATH}"
    fi

    # CERTIFICATE_NAME="${NAME_LOWER}vpn.${DOMAIN}"
    CERTIFICATE_NAME="${PREFIX}vpn.${DOMAIN}"
    # CERTIFICATE_NAME="${SIDE}"
    CERTIFICATE_PATH="${TLS_PATH}/${SIDE}.crt"
    CERTIFICATE_KEY_PATH="${TLS_PATH}/${SIDE}.key"
    DATA_PATH="${TEMPLATES_DIR}/${DOMAIN}"
    DATA_FILE="${DATA_PATH}/tls.${SIDE}.json"

    # Gerar certificados TLS para orderers e peers
    # if [ "${TYPE}" == "orderer" ] || [ "${TYPE}" == "peer" ]; then
    #     CERTIFICATE_PATH="${TLS_PATH}/server.crt"
    #     CERTIFICATE_KEY_PATH="${TLS_PATH}/server.key"
    #     DATA_FILE="${DATA_PATH}/tls.server.json"

    #     create_certificate ${PROVISIONER_NAME} ${PROVISIONER_PASSWORD} ${DOMAIN} ${CERTIFICATE_NAME} ${CERTIFICATE_PATH} ${CERTIFICATE_KEY_PATH} ${DATA_FILE}
    # # fi
    # else
    #     CERTIFICATE_PATH="${TLS_PATH}/client.crt"
    #     CERTIFICATE_KEY_PATH="${TLS_PATH}/client.key"
    #     DATA_FILE="${DATA_PATH}/tls.client.json"

    #     create_certificate ${PROVISIONER_NAME} ${PROVISIONER_PASSWORD} ${DOMAIN} ${CERTIFICATE_NAME} ${CERTIFICATE_PATH} ${CERTIFICATE_KEY_PATH} ${DATA_FILE}
    # fi
    create_certificate "${PROVISIONER_NAME}" "${PROVISIONER_PASSWORD}" "${DOMAIN}" "${CERTIFICATE_NAME}" "${CERTIFICATE_PATH}" "${CERTIFICATE_KEY_PATH}" "${DATA_FILE}"

    local SIGN_CERTS_PATH="${MSP_PATH}/signcerts"
    local KEYSTORE_PATH="${MSP_PATH}/keystore"

    mkdir -p "${SIGN_CERTS_PATH}"
    mkdir -p "${KEYSTORE_PATH}"

    CERTIFICATE_PATH="${SIGN_CERTS_PATH}/${CERTIFICATE_NAME}-cert.pem"
    CERTIFICATE_KEY_PATH="${KEYSTORE_PATH}/${CERTIFICATE_NAME}-key.pem"

    DATA_FILE="${DATA_PATH}/sign.${DATA_TYPE}.json"

    create_certificate "${PROVISIONER_NAME}" "${PROVISIONER_PASSWORD}" "${DOMAIN}" "${CERTIFICATE_NAME}" "${CERTIFICATE_PATH}" "${CERTIFICATE_KEY_PATH}" "${DATA_FILE}"

    if [ "${TYPE}" == "peer" ]; then
        generate_msp_config "${MSP_PATH}" # "COP" "Peer"
    fi
}

export -f generate_msp
