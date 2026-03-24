#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../setup/installation/install_ca_certificate.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../logging/stdout/info.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../setup/installation/install_packages.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate_msp_config.sh"

#
# Generate a cache domain msp
#
function generate_cache_domain_msp() {
    local DOMAIN
    local FINGERPRINT
    local ROOT_CA_PATH
    local CACHE_DOMAIN_PATH
    local MSP_DOMAIN_CACHE_PATH
    local TLS_DOMAIN_CACHE_PATH

    DOMAIN=$1
    FINGERPRINT=$2

    install_ca_certificate "${DOMAIN}" "${FINGERPRINT}"

    ROOT_CA_PATH="/usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt"

    CACHE_DOMAIN_PATH="${CACHE_DIR}/${DOMAIN}"
    MSP_DOMAIN_CACHE_PATH="${CACHE_DOMAIN_PATH}/msp"
    TLS_DOMAIN_CACHE_PATH="${CACHE_DOMAIN_PATH}/tls"

    mkdir -p "${MSP_DOMAIN_CACHE_PATH}"/admincerts
    mkdir -p "${MSP_DOMAIN_CACHE_PATH}"/cacerts
    mkdir -p "${MSP_DOMAIN_CACHE_PATH}"/tlscacerts

    mkdir -p "${TLS_DOMAIN_CACHE_PATH}"

    # Create simbolic link to root domain certificate
    if [ ! -f "${MSP_DOMAIN_CACHE_PATH}"/cacerts/ca-cert.pem ]; then
        info "Creating simbolic link to root domain certificate: ${ROOT_CA_PATH} -> ${MSP_DOMAIN_CACHE_PATH}/cacerts/ca-cert.pem"
        ln -s "${ROOT_CA_PATH}" "${MSP_DOMAIN_CACHE_PATH}"/cacerts/ca-cert.pem
    fi

    if [ ! -f "${MSP_DOMAIN_CACHE_PATH}"/tlscacerts/ca-cert.pem ]; then
        info "Creating simbolic link to root domain certificate: ${ROOT_CA_PATH} -> ${MSP_DOMAIN_CACHE_PATH}/tlscacerts/ca-cert.pem"
        ln -s "${ROOT_CA_PATH}" "${MSP_DOMAIN_CACHE_PATH}"/tlscacerts/ca-cert.pem
    fi

    # if [ ! -f ${TLS_DOMAIN_CACHE_PATH}/ca.crt ]; then
    #     info "Creating simbolic link to root domain certificate: ${ROOT_CA_PATH} -> ${TLS_DOMAIN_CACHE_PATH}/ca.crt"
    #     ln -s ${ROOT_CA_PATH} ${TLS_DOMAIN_CACHE_PATH}/ca.crt
    # fi

    # Download intermediate certificate for the domain ${DOMAIN}
    local INTERMEDIATE_CA_PATH="${MSP_DOMAIN_CACHE_PATH}/intermediatecerts/intermediate-cert.pem"
    local INTERMEDIATE_CA_URL="https://ca.docker.vpn.${DOMAIN}/1.0/intermediates.pem"

    if [ ! -f "${INTERMEDIATE_CA_PATH}" ]; then
        info "Downloading intermediate CA certificate for ${DOMAIN}"
        mkdir -p "${MSP_DOMAIN_CACHE_PATH}"/intermediatecerts

        install_packages wget

        wget --ca-certificate="${ROOT_CA_PATH}" -O "${INTERMEDIATE_CA_PATH}" "${INTERMEDIATE_CA_URL}"
    fi

    # Link intermediate certificate to tlsintermediatecerts
    local TLS_INTERMEDIATE_CA_PATH="${MSP_DOMAIN_CACHE_PATH}/tlsintermediatecerts/intermediate-cert.pem"

    if [ ! -f "${TLS_INTERMEDIATE_CA_PATH}" ]; then
        info "Creating simbolic link to intermediate certificate: ${INTERMEDIATE_CA_PATH} -> ${TLS_INTERMEDIATE_CA_PATH}"
        mkdir -p "${MSP_DOMAIN_CACHE_PATH}"/tlsintermediatecerts

        ln -s "${INTERMEDIATE_CA_PATH}" "${TLS_INTERMEDIATE_CA_PATH}"
    fi

    if [ ! -f "${TLS_DOMAIN_CACHE_PATH}"/ca.crt ]; then
        info "Creating blunded root domain certificate with intermediate: ${TLS_DOMAIN_CACHE_PATH}/ca.crt"
        cat "${ROOT_CA_PATH}" "${INTERMEDIATE_CA_PATH}" > "${TLS_DOMAIN_CACHE_PATH}"/ca.crt
    fi

    if [ ! -f "${MSP_DOMAIN_CACHE_PATH}"/config.yaml ]; then
        generate_msp_config "${MSP_DOMAIN_CACHE_PATH}" #"Peer"
    fi
}

export -f generate_cache_domain_msp
