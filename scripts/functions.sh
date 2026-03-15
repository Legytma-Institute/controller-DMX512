#!/usr/bin/env bash

#
# General use functions
#

# # Platform variables
# OS=$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')
# ARCH=$(uname -m | sed 's/x86_64/amd64/g' | sed 's/aarch64/arm64/g')
# PLATFORM=${OS}-${ARCH}

# Current directory
CURRENT_DIR=$(pwd)

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

# Default base path
DEFAULT_BASE_PATH="${CURRENT_DIR}/.default"

# Source base path
SOURCE_BASE_PATH="${CURRENT_DIR}/env"

# Cache directory
CACHE_DIR="${CURRENT_DIR}/.cache"

# Templates directory
TEMPLATES_DIR="${CURRENT_DIR}/.templates"

# Certificates directory
CERTS_DIR="${CURRENT_DIR}/step-certs"

# Channel artifacts directory
CHANNEL_ARTIFACTS_DIR="${CURRENT_DIR}/channel-artifacts"

#
# Print error message to stderr
#
function error() {
    echo -e "\033[31m$*\033[0m" >&2
}

export -f error

#
# Print warning message to stderr
#
function warning() {
    echo -e "\033[33m$*\033[0m" >&2
}

export -f warning

#
# Print info message to stdout
#
function info() {
    echo -e "\033[32m$*\033[0m" >&2
}

export -f info

#
# Print debug message to stdout
#
function debug() {
    echo -e "\033[34m$*\033[0m" >&2
}

export -f debug

#
# Confirm action in green
#
function confirm() {
    read -p "\033[32m$1 (y/N):\033[0m " -n 1 -r
    echo
    if [[ ${REPLY} =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

export -f confirm

#
# Load .env file
#
function load_env_file() {
    if [ -f "${CURRENT_DIR}/.env" ]; then
        install_packages direnv

        direnv dotenv > /tmp/.env.tmp

        # shellcheck source=/dev/null
        . /tmp/.env.tmp
    fi
}

export -f load_env_file

#
# Get input with default value
#
function get_input() {
    local PROMPT
    local DEFAULT
    local PROMPT_DEFAULT
    local INPUT

    PROMPT=$1
    DEFAULT=$2
    PROMPT_DEFAULT=""
    INPUT=""

    if [ -n "${DEFAULT}" ]; then
        PROMPT_DEFAULT=" [${DEFAULT}]"
    fi

    read -rp "\033[32m${PROMPT}${PROMPT_DEFAULT}:\033[0m " INPUT

    if [ -z "${INPUT}" ]; then
        echo "${DEFAULT}"
    else
        echo "${INPUT}"
    fi
}

export -f get_input

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

#
# Generate a random password
#
function generate_password() {
    tr -cd '[:alnum:]' < /dev/urandom | fold -w40 | head -n 1
}

export -f generate_password

#
# Generate a random username
#
function generate_username() {
    tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n 1 | tr '[:upper:]' '[:lower:]'
}

export -f generate_username

#
# Add alias to file
#
function add_alias() {
    local ALIAS_NAME
    local ALIAS_VALUE
    local FILES
    local FILE

    ALIAS_NAME=$1
    ALIAS_VALUE=$2

    shift 2

    FILES=("$@")

    # If array size is 0, set default files
    if [ ${#FILES[@]} -eq 0 ]; then
        FILES=("${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.bash_profile" "${HOME}/.profile")
    fi

    for FILE in "${FILES[@]}"; do
        if [ -f "${FILE}" ]; then
            if ! grep -q "alias ${ALIAS_NAME}='${ALIAS_VALUE}'" "${FILE}"; then
                echo "alias ${ALIAS_NAME}='${ALIAS_VALUE}'" >> "${FILE}"
            fi
        fi
    done
}

export -f add_alias

#
# Add export to file
#
function add_export() {
    local EXPORT_VALUE
    local FILES
    local FILE

    EXPORT_VALUE=$1

    shift 1

    FILES=("$@")

    # If array size is 0, set default files
    if [ ${#FILES[@]} -eq 0 ]; then
        FILES=("${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.bash_profile" "${HOME}/.profile")
    fi

    for FILE in "${FILES[@]}"; do
        if [ -f "${FILE}" ]; then
            if ! grep -q "export ${EXPORT_VALUE}" "${FILE}"; then
                echo "export ${EXPORT_VALUE}" >> "${FILE}"
            fi
        fi
    done
}

export -f add_export

#
# Add source to file
#
function add_source() {
    local FUNCTION_SOURCE
    local FILES
    local FILE

    FUNCTION_SOURCE=$1

    shift 1

    FILES=("$@")

    # If array size is 0, set default files
    if [ ${#FILES[@]} -eq 0 ]; then
        FILES=("${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.bash_profile" "${HOME}/.profile")
    fi

    for FILE in "${FILES[@]}"; do
        if [ -f "${FILE}" ]; then
            if ! grep -q "source ${FUNCTION_SOURCE}" "${FILE}"; then
                echo "source ${FUNCTION_SOURCE}" >> "${FILE}"
            fi
        fi
    done
}

export -f add_source

#
# Add this alias and function source to file
#
function add_this_alias_and_function_source() {
    add_alias "this" "${SCRIPT_DIR}/this.sh" "${@}"
    add_source "${SCRIPT_DIR}/functions.sh" "${@}"
}

export -f add_this_alias_and_function_source

#
# Configure current directory as safe directory
#
function configure_safe_directories() {
    local DIRECTORIES

    DIRECTORIES=("$@")

    # If array size is 0, set default directory
    if [ ${#DIRECTORIES[@]} -eq 0 ]; then
        DIRECTORIES=("${CURRENT_DIR}")
    fi

    for DIRECTORY in "${DIRECTORIES[@]}"; do
        git config --global --add safe.directory "${DIRECTORY}"
    done
}

export -f configure_safe_directories

#
# Configure GIT
#
function configure_git() {
    git config --global user.email "windol@legytma.com.br"
    git config --global user.name "Alex Manoel Ferreira Silva (Windol)"
    git config --global user.signingkey "key::ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAEAQC2FBLyt5JGrqpmxp+YJvuv+rzd248D1Z/u04wMss6Ku0swq5hfnp6jwKdouY8iBKOTn57F/j9tBAavDso0aOPpKQDzWh+xJ7u4Juqeo23uI0A8lfYLWqoGk+wTfPu41PIiUtp+ekyGVTqpvfouPrL++6GOYWvPF37AvSC+Vif4KiIa514wOmeipHF7JgvVO7Dt9o+QzmlEqirqbl3v7u2IQXoVFUPGPCJM9Qt6KVp5sZ57+IZvX7LLKiY9dyFNZYfHAGHRRTKXTbl2/YyaxVuZmTX8BjcGqDoU5cXeD2GZuf2ZCZrUf1VxlzRYtLYP9mFjUvvDNC1L0dec+z8cI3Pf0FJjGXrDuUBSBMG7YC34HnA4BThcPwKS0q/mvKeg1XV3vlM1+9CR4UK7BpJXcQsDXPFZHdhDNXWvor46nmqUvhzLJJGeUIwl/ScP7nuLvNqky5JhZ+KjncBLuq/GCugGzjUDTxXotMZa7jHrAQo+AcqtXkLCrAe7dtFNTse6jwEdwEBcF6a4oNJJmRR97vxRPu0k80doyA3n1K4VVzhMiO5lsqvtlGMvefhp4ICds9fUW+Lqh9cXkQH4JXsvi+gT7u67LoNI5yYzKEn6YuCOeSVmtlJV8j8M3LkodBLNP9jo4HRgzIPQtSr+cWfcNpnUI1Z4WUu6UJ2w+TccsZGYH4QaMd6ovnXfMqz0JGTJkFeSfeZFVdUccAeB1xRhNLJYi4iBjOqAUVSrlJhCGD9bqo3bjn/ZEYaUQh+pBrSnpvPyFmbtsez11dV++Ix56qRacIVQVa0W0hr6JpTOHNkZQvxsDy2LPgeoTVYn0SuVEK1FFZLH0BSqxIfKr5KKcJiJZXWoMLRpL/vJMvBoRU1OGIHF0v1DpL5kdFPTEgAE/bA1rzW+933or7LCsI37/XpoKSvFPSVU57KDEjnRDjOLwLQZUZUL8AOQeSQqd7NJEarSFfoSkDgeGnGzGWUJlpDc6UtIx317NLj3a8Vnx7w1OJZBHf6BgTL2Jbq3VhP8MXoXJT8jswwxl6VPXOM7/7SCGPUP61l7M4C26M9QKQWBVLRDxR4Vc0slKHJkteKhI5LUILlYJDfmXcYLafG4zebvTGfmLBvh9uRbIse1ygbr4HqWBCIrr3blG2pCmWvlwlGH7CrHgJdDsHQQOI4XVvgfCqOBYkdMYJeAmyy2+Uw55gdNdHqtdspy6qXo/pgTVW8kgXfOuAr18ZpVHyZD59BODWEqaOSlV0ju/QsjRUwKQZS+234tDRGKdLpK879EpNVPOd6caQdHHWFtaSSgiRV4FPSHVUIxd5cSTD7P+3VJB8J6rY4cm32rlAsfNyhlXio4I1/aL79p8Q8vvYkR6FM5 rsa-key-20221121"
    git config --global gpg.format ssh
    git config --global commit.gpgsign true

    configure_safe_directories "${CURRENT_DIR}"
}

export -f configure_git

#
# Cleanup
#
function cleanup() {
    if [ "$1" == "--force" ] || confirm "Do you want to continue with the complete cleanup?"; then
        debug "Stopping and removing previous containers"

        docker compose down --volumes --remove-orphans

        debug "Removing old artifacts"
        sudo rm -rf "${CHANNEL_ARTIFACTS_DIR}"/*
        sudo rm -rf "${CERTS_DIR}"/*
        sudo rm -rf /tmp/.env.tmp
    fi
}

export -f cleanup

#
# Generate a msp config file
#
function generate_msp_config() {
    local MSP_DIR
    local ORGANIZATION_UNIT_IDENTIFIERS
    local MSP_CONFIG_FILE

    MSP_DIR=$1
    shift 1
    ORGANIZATION_UNIT_IDENTIFIERS=("$@")

    debug "Generating MSP config for ${MSP_DIR}"

    MSP_CONFIG_FILE="${MSP_DIR}/config.yaml"

    # Remove existing config file
    rm -rf "${MSP_CONFIG_FILE}"

    # Create config.yaml starting with OrganizationalUnitIdentifiers if any OUs are provided
    if [ ${#ORGANIZATION_UNIT_IDENTIFIERS[@]} -gt 0 ]; then
        echo "OrganizationalUnitIdentifiers:" > "${MSP_CONFIG_FILE}"

        for OU in "${ORGANIZATION_UNIT_IDENTIFIERS[@]}"; do
            echo "  - Certificate: cacerts/ca-cert.pem" >> "${MSP_CONFIG_FILE}"
            echo "    OrganizationalUnitIdentifier: ${OU}" >> "${MSP_CONFIG_FILE}"
        done

        echo "" >> "${MSP_CONFIG_FILE}"
    fi

    # Add NodeOUs section
    cat >> "${MSP_CONFIG_FILE}" << EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca-cert.pem
    OrganizationalUnitIdentifier: Client
  PeerOUIdentifier:
    Certificate: intermediatecerts/intermediate-cert.pem
    OrganizationalUnitIdentifier: Peer
  AdminOUIdentifier:
    Certificate: intermediatecerts/intermediate-cert.pem
    OrganizationalUnitIdentifier: Admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca-cert.pem
    OrganizationalUnitIdentifier: Orderer
EOF
}

export -f generate_msp_config

#
# Install packages if a command is not found
#
function install_packages() {
    local COMMAND=$1
    shift 1

    local PACKAGES=$1

    if ! command -v "${COMMAND}" &> /dev/null; then
        sudo apt update

        if [ -z "${PACKAGES}" ]; then
            sudo apt install -y "${COMMAND}" || exit 1
        else
            sudo apt install -y "$@" || exit 1
        fi
    fi
}

export -f install_packages

#
# Install docker
#
function install_docker() {
    if ! command -v docker &> /dev/null; then
        sudo apt update
        sudo apt install -y ca-certificates curl

        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # Add the repository to Apt sources:
        # shellcheck disable=SC1091
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-${VERSION_CODENAME}}") stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || exit 1

        sudo systemctl enable docker.service
        sudo systemctl enable containerd.service
        sudo systemctl start containerd.service
        sudo systemctl start docker.service
    fi
}

export -f install_docker

#
# Install step cli
#
function install_step_cli() {
    if [ -z "$(command -v step)" ]; then
        debug "Installing step cli..."

        install_packages wget

        wget -O /tmp/step-cli_amd64.deb https://dl.smallstep.com/cli/docs-cli-install/latest/step-cli_amd64.deb

        sudo dpkg -i /tmp/step-cli_amd64.deb
        rm -rf /tmp/step-cli_amd64.deb
    fi
}

export -f install_step_cli

#
# Install CA certificate for a given domain
#
function install_ca_certificate() {
    local DOMAIN
    local FINGERPRINT
    local ROOT_CA_PATH
    local STEP_CA_URL

    DOMAIN=$1
    FINGERPRINT=$2

    ROOT_CA_PATH="/usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt"
    STEP_CA_URL="https://ca.docker.vpn.${DOMAIN}"

    if [ ! -f "${ROOT_CA_PATH}" ]; then
        install_step_cli

        debug "Installing root CA certificate for ${DOMAIN}"
        sudo step ca root "${ROOT_CA_PATH}" --force --ca-url "${STEP_CA_URL}" --fingerprint "${FINGERPRINT}"
        sudo step certificate install --all "${ROOT_CA_PATH}"
        sudo chmod 644 "${ROOT_CA_PATH}"

        sudo update-ca-certificates
    fi
}

export -f install_ca_certificate

#
# Get latest version of a given repository
#
function get_latest_version() {
    local REPOSITORY
    local VERSION
    local URL

    REPOSITORY=$1

    URL="https://github.com/${REPOSITORY}/releases/latest"

    install_packages curl

    VERSION=$(curl -sLf "${URL}" | grep -oP "/${REPOSITORY}/releases/tag/\K[^\"]+" | head -n1)

    echo "${VERSION}"
}

export -f get_latest_version

#
# Install latest version of a given repository
#
function install_latest_version() {
    local REPOSITORY
    local SOURCE_BINARY
    local DESTINATION_BINARY
    local VERSION
    local URL
    local TMPDIR
    local FINAL_PATH
    local CANDIDATE

    REPOSITORY=$1
    SOURCE_BINARY=$2
    DESTINATION_BINARY=$3

    if ! command -v "${DESTINATION_BINARY}" &> /dev/null; then
        VERSION=$(get_latest_version "${REPOSITORY}")

        debug "Installing ${DESTINATION_BINARY} from ${REPOSITORY} version ${VERSION}..."

        URL="https://github.com/${REPOSITORY}/releases/download/${VERSION}/${SOURCE_BINARY}"

        install_packages curl

        curl -Lf "${URL}" -o "/tmp/${SOURCE_BINARY}"

        # Detecta extensão e extrai/renomeia para produzir um arquivo final em /tmp/${DESTINATION_BINARY}
        TMPDIR="$(mktemp -d)"
        FINAL_PATH="${TMPDIR}/${DESTINATION_BINARY}"

        # Ferramentas possivelmente necessárias para extração
        # (ignora erros se o gerenciador não existir; adapte install_packages ao seu ambiente)
        install_packages tar tar xz-utils bzip2
        install_packages unzip
        install_packages gunzip gzip

        case "${SOURCE_BINARY}" in
            *.tar.gz|*.tgz)
                tar -xzf "/tmp/${SOURCE_BINARY}" -C "${TMPDIR}"
                ;;
            *.tar.xz)
                tar -xJf "/tmp/${SOURCE_BINARY}" -C "${TMPDIR}"
                ;;
            *.tar.bz2)
                tar -xjf "/tmp/${SOURCE_BINARY}" -C "${TMPDIR}"
                ;;
            *.zip)
                unzip -q "/tmp/${SOURCE_BINARY}" -d "${TMPDIR}"
                ;;
            *.gz) # gzip simples (não tar)
                # Se o nome terminar com .gz, descompacta para o nome destino
                gunzip -c "/tmp/${SOURCE_BINARY}" > "${FINAL_PATH}"
                ;;
            *)
                # Não compactado: apenas copia/renomeia
                cp "/tmp/${SOURCE_BINARY}" "${FINAL_PATH}"
                ;;
        esac

        # Se foi um pacote (tar/zip), precisamos escolher o binário dentro dele
        if [ ! -s "${FINAL_PATH}" ]; then
            # Primeiro tenta um arquivo com o mesmo nome do DESTINATION_BINARY
            CANDIDATE="$(find "${TMPDIR}" -type f -name "${DESTINATION_BINARY}" 2>/dev/null | head -n1)"

            if [ -z "${CANDIDATE}" ]; then
                # Se não houver, pega o primeiro arquivo executável
                CANDIDATE="$(find "${TMPDIR}" -type f -perm -u+x -o -perm -g+x -o -perm -o+x 2>/dev/null | head -n1)"
            fi

            if [ -z "${CANDIDATE}" ]; then
                # Como fallback, pega o primeiro arquivo regular
                CANDIDATE="$(find "${TMPDIR}" -type f 2>/dev/null | head -n1)"
            fi

            if [ -z "${CANDIDATE}" ]; then
                echo "Erro: não foi possível localizar um binário dentro do pacote ${SOURCE_BINARY}" >&2
                rm -rf "${TMPDIR}" "/tmp/${SOURCE_BINARY}"
                return 1
            fi

            # Copia o candidato para o nome final esperado
            cp "${CANDIDATE}" "${FINAL_PATH}"
        fi

        chmod +x "${FINAL_PATH}"
        sudo mv "${FINAL_PATH}" "/usr/local/bin/${DESTINATION_BINARY}"

        debug "${DESTINATION_BINARY} installed successfully"
    fi
}

export -f install_latest_version

#
# Install yq
#
function install_yq() {
    install_latest_version "mikefarah/yq" "yq_linux_amd64" "yq"
 }

export -f install_yq

#
# Install fablo
#
function install_fablo() {
    install_latest_version "hyperledger-labs/fablo" "fablo.sh" "fablo"
}

export -f install_fablo

#
# Install firefly
#
function install_firefly() {
    if ! command -v ff &> /dev/null; then
        debug "Installing firefly..."

        install_packages go golang

        go install github.com/hyperledger/firefly-cli/ff@latest

        debug "firefly installed successfully"
    fi
}

export -f install_firefly

#
# Install node
#
function install_node() {
    if ! command -v node &> /dev/null; then
        debug "Installing node..."

        # Install Node.js LTS
        nvm install --lts

        debug "Node installed successfully"
    fi
}

export -f install_node

#
# Install Flutter SDK
#
function install_flutter() {
    local FLUTTER_VERSION

    FLUTTER_VERSION=$1

    if ! command -v flutter &> /dev/null; then
        install_android_sdk
        install_chrome

        debug "Installing Flutter SDK..."

        sudo apt install -y curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build libgtk-3-dev liblzma-dev mesa-utils

        if [ -z "${FLUTTER_VERSION}" ]; then
            FLUTTER_VERSION="3.38.6"
        fi

        curl -o /tmp/flutter_linux.tar.xz "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

        mkdir -p "${HOME}/develop/"

        tar -xf /tmp/flutter_linux.tar.xz -C "${HOME}/develop/"

        rm -rf /tmp/flutter_linux.tar.xz

        add_export "PATH=\"\${HOME}/develop/flutter/bin:\${PATH}\""

        export PATH="${HOME}/develop/flutter/bin:${PATH}"

        flutter --suppress-analytics --disable-analytics
        flutter doctor --android-licenses << EOF
y
y
y
y
y
y
y
y
EOF

        flutter doctor
        flutter --version
        dart --version

        debug "Flutter SDK installed successfully"
    fi
}

export -f install_flutter

#
# Install Android SDK
#
function install_android_sdk() {
    local COMMAND_LINE_TOOLS_URL

    if ! command -v sdkmanager &> /dev/null; then
        COMMAND_LINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip"

        install_packages curl
        install_packages unzip

        debug "Installing Android SDK..."

        mkdir -p "${HOME}/android/sdk/cmdline-tools"

        curl -o /tmp/commandlinetools-linux.zip "${COMMAND_LINE_TOOLS_URL}"

        unzip -q /tmp/commandlinetools-linux.zip -d /tmp/commandlinetools-linux

        mv /tmp/commandlinetools-linux/cmdline-tools "${HOME}/android/sdk/cmdline-tools/latest"

        rm -rf /tmp/commandlinetools-linux.zip
        rm -rf /tmp/commandlinetools-linux

        add_export "ANDROID_HOME=\"\${HOME}/android/sdk\""
        add_export "PATH=\"\${ANDROID_HOME}/cmdline-tools/latest/bin:\${PATH}\""
        add_export "PATH=\"\${ANDROID_HOME}/platform-tools:\${PATH}\""

        export ANDROID_HOME="${HOME}/android/sdk"
        export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${PATH}"
        export PATH="${ANDROID_HOME}/platform-tools:${PATH}"

        sdkmanager --licenses << EOF
y
y
y
y
y
y
y
y
EOF

        sdkmanager --install "platform-tools" "platforms;android-36.1" "build-tools;36.1.0" "cmake;4.1.2" "ndk;29.0.14206865"
        sdkmanager --update

        debug "Android SDK installed successfully"
    fi
}

export -f install_android_sdk

#
# Install Chrome browser
#
function install_chrome() {
    if ! command -v google-chrome &> /dev/null; then
        debug "Installing Chrome browser..."

        install_packages curl

        curl -o /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

        sudo apt install -y /tmp/google-chrome.deb

        rm -rf /tmp/google-chrome.deb

        sudo ln -s /usr/bin/google-chrome /usr/local/bin/chrome

        debug "Chrome browser installed successfully"
    fi
}

export -f install_chrome

#
# Install GO
#
function install_go() {
    local GO_VERSION

    GO_VERSION=$1

    if ! command -v go &> /dev/null; then
        debug "Installing Go..."

        install_packages curl

        if [ -z "${GO_VERSION}" ]; then
            GO_VERSION="1.25.6"
        fi

        curl -L -o /tmp/go.linux-amd64.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"

        sudo rm -rf /usr/local/go

        sudo tar -C /usr/local -xzf /tmp/go.linux-amd64.tar.gz

        rm -rf /tmp/go.linux-amd64.tar.gz

        add_export "PATH=\"/usr/local/go/bin:\${PATH}\""

        export PATH="/usr/local/go/bin:${PATH}"

        go version

        debug "Go installed successfully"
    fi
}

export -f install_go

# #
# # Download a intermediate certificate for a given domain
# #
# function download_intermediate_certificate() {
#     local DOMAIN
#     local ROOT_CA_PATH
#     local INTERMEDIATE_CA_PATH
#     local INTERMEDIATE_CA_URL

#     DOMAIN=$1

#     ROOT_CA_PATH="/usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt"
#     INTERMEDIATE_CA_PATH="${CACHE_DIR}/${DOMAIN}/intermediates.pem"
#     INTERMEDIATE_CA_URL="https://ca.docker.vpn.${DOMAIN}/1.0/intermediates.pem"

#     if [ ! -f ${INTERMEDIATE_CA_PATH} ]; then
#         echo "Downloading intermediate CA certificate for ${DOMAIN}"
#         mkdir -p ${CACHE_DIR}/${DOMAIN}

#         install_packages wget

#         wget --ca-certificate=${ROOT_CA_PATH} -O ${INTERMEDIATE_CA_PATH} ${INTERMEDIATE_CA_URL}
#     fi
# }

# export -f download_intermediate_certificate

#
# Check if a provisioner exists
#
function check_provisioner_exists() {
    local PROVISIONER_NAME
    local DOMAIN
    local CA_URL
    local ROOT_PATH
    local PROVISIONER_LIST
    local PROVISIONER_RESULT

    PROVISIONER_NAME=$1
    DOMAIN=$2

    CA_URL="https://ca.docker.vpn.${DOMAIN}"
    ROOT_PATH="/usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt"

    PROVISIONER_LIST=$(step ca provisioner list --ca-url "${CA_URL}" --root "${ROOT_PATH}")

    install_packages jq

    # Get the list of provisioners, return only the name of the provisioners and filter by the PROVISIONER_NAME
    PROVISIONER_RESULT=$(echo "${PROVISIONER_LIST}" | jq -r '.[] | .name' | grep "${PROVISIONER_NAME}")

    if [ "${PROVISIONER_RESULT}" == "${PROVISIONER_NAME}" ]; then
        return 0
    else
        return 1
    fi
}

export -f check_provisioner_exists

#
# Create a new provisioner
#
function create_provisioner() {
    local PROVISIONER_NAME
    local PROVISIONER_PASSWORD
    local DOMAIN
    local ADMIN_PROVISIONER_SUBJECT
    local ADMIN_PROVISIONER_NAME
    local ADMIN_PROVISIONER_PASSWORD
    local PROVISIONER_TEMPLATE_FILE
    local ROOT_PATH
    local CA_URL
    local PROVISIONER_CREATE_RESULT

    PROVISIONER_NAME=$1
    PROVISIONER_PASSWORD=$2
    DOMAIN=$3
    ADMIN_PROVISIONER_SUBJECT=$4
    ADMIN_PROVISIONER_NAME=$5
    ADMIN_PROVISIONER_PASSWORD=$6

    if check_provisioner_exists "${PROVISIONER_NAME}" "${DOMAIN}"; then
        info "Provisioner ${PROVISIONER_NAME}@${DOMAIN} already exists"
        return 0
    fi

    PROVISIONER_TEMPLATE_FILE="${TEMPLATES_DIR}/${DOMAIN}/certificate.tpl"
    ROOT_PATH="/usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt"
    CA_URL="https://ca.docker.vpn.${DOMAIN}"

    info "Creating provisioner ${PROVISIONER_NAME}@${DOMAIN}"

    step ca provisioner add "${PROVISIONER_NAME}" --type JWK \
        --ca-url "${CA_URL}" \
        --root "${ROOT_PATH}" \
        --admin-subject "${ADMIN_PROVISIONER_SUBJECT}" \
        --admin-provisioner "${ADMIN_PROVISIONER_NAME}" \
        --admin-password-file <(echo -n "${ADMIN_PROVISIONER_PASSWORD}") \
        --x509-template "${PROVISIONER_TEMPLATE_FILE}" \
        --x509-max-dur 43200h \
        --x509-default-dur 8640h \
        --create \
        --password-file <(echo -n "${PROVISIONER_PASSWORD}")

    PROVISIONER_CREATE_RESULT=$?

    if [ "${PROVISIONER_CREATE_RESULT}" -ne 0 ]; then
        error "Error creating provisioner ${PROVISIONER_NAME}@${DOMAIN}: ${PROVISIONER_CREATE_RESULT}"
    else
        info "Provisioner ${PROVISIONER_NAME}@${DOMAIN} created successfully"
    fi
}

export -f create_provisioner

#
# List all provisioners
#
function list_provisioners() {
    local DOMAIN
    local CA_URL
    local ROOT_PATH

    DOMAIN=$1

    CA_URL="https://ca.docker.vpn.${DOMAIN}"
    ROOT_PATH="/usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt"

    step ca provisioner list --ca-url "${CA_URL}" --root "${ROOT_PATH}"
}

export -f list_provisioners

#
# Remove a provisioner
#
function remove_provisioner() {
    local PROVISIONER_NAME
    local DOMAIN
    local ADMIN_PROVISIONER_SUBJECT
    local ADMIN_PROVISIONER_NAME
    local ADMIN_PROVISIONER_PASSWORD
    local ROOT_PATH
    local CA_URL

    PROVISIONER_NAME=$1
    DOMAIN=$2
    ADMIN_PROVISIONER_SUBJECT=$3
    ADMIN_PROVISIONER_NAME=$4
    ADMIN_PROVISIONER_PASSWORD=$5

    if ! check_provisioner_exists "${PROVISIONER_NAME}" "${DOMAIN}"; then
        info "Provisioner ${PROVISIONER_NAME}@${DOMAIN} does not exist"
        return 0
    fi

    ROOT_PATH="/usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt"
    CA_URL="https://ca.docker.vpn.${DOMAIN}"

    info "Removing provisioner ${PROVISIONER_NAME}@${DOMAIN}"

    step ca provisioner remove "${PROVISIONER_NAME}" \
        --ca-url "${CA_URL}" \
        --root "${ROOT_PATH}" \
        --admin-subject "${ADMIN_PROVISIONER_SUBJECT}" \
        --admin-provisioner "${ADMIN_PROVISIONER_NAME}" \
        --admin-password-file <(echo -n "${ADMIN_PROVISIONER_PASSWORD}")
}

export -f remove_provisioner

#
# Get a token for a given domain and provisioner
#
function get_provisioner_token() {
    local PROVISIONER_NAME
    local PROVISIONER_PASSWORD
    local DOMAIN
    local STEP_CA_URL
    local ROOT_CA_PATH

    PROVISIONER_NAME=$1
    PROVISIONER_PASSWORD=$2
    DOMAIN=$3

    STEP_CA_URL="https://ca.docker.vpn.${DOMAIN}"
    ROOT_CA_PATH="/usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt"

    >&2 echo "Getting token for ${PROVISIONER_NAME}@${DOMAIN}"

    step ca token --ca-url "${STEP_CA_URL}" --root "${ROOT_CA_PATH}" --provisioner "${PROVISIONER_NAME}" --password-file <(echo -n "${PROVISIONER_PASSWORD}") \
        "orderer0.vpn.${DOMAIN}"
}

export -f get_provisioner_token

#
# Create a certificate for a given domain
#
function create_certificate() {
    local PROVISIONER_NAME
    local PROVISIONER_PASSWORD
    local DOMAIN
    local CERTIFICATE_NAME
    local CERTIFICATE_PATH
    local CERTIFICATE_KEY_PATH
    local DATA_FILE
    local STEP_CA_URL
    local ROOT_CA_PATH

    PROVISIONER_NAME=$1
    PROVISIONER_PASSWORD=$2
    DOMAIN=$3
    CERTIFICATE_NAME=$4
    CERTIFICATE_PATH=$5
    CERTIFICATE_KEY_PATH=$6
    DATA_FILE=$7

    STEP_CA_URL="https://ca.docker.vpn.${DOMAIN}"
    ROOT_CA_PATH="/usr/local/share/ca-certificates/${DOMAIN}_root_ca.crt"

    info "Generating certificate ${CERTIFICATE_NAME}"

    step ca certificate --force --ca-url "${STEP_CA_URL}" --root "${ROOT_CA_PATH}" --provisioner "${PROVISIONER_NAME}" --password-file <(echo -n "${PROVISIONER_PASSWORD}") \
        "${CERTIFICATE_NAME}" "${CERTIFICATE_PATH}" "${CERTIFICATE_KEY_PATH}" --set-file "${DATA_FILE}" --not-before -86400s --not-after 8640h --san "${CERTIFICATE_NAME}"
        # --set isCA=false --set maxPathLen=0 --set 'keyUsage=["digitalSignature", "keyEncipherment"]' #--set organizationalUnit=${PROVISIONER_NAME}
}

export -f create_certificate

#
# Create certificate template for a given domain
#
function create_certificate_template() {
    local DOMAIN
    local TEMPLATE_PATH
    local TEMPLATE_FILE

    DOMAIN=$1

    TEMPLATE_PATH="${TEMPLATES_DIR}/${DOMAIN}"
    TEMPLATE_FILE="${TEMPLATE_PATH}/certificate.tpl"

    if [ ! -f "${TEMPLATE_FILE}" ]; then
        info "Creating template ${TEMPLATE_FILE}"

        mkdir -p "${TEMPLATE_PATH}"

        cat > "${TEMPLATE_FILE}" << EOF
{
  "subject": {
    {{- if .Subject.Country }}
        "country": {{ toJson .Subject.Country }},
    {{- else }}
        "country": {{ toJson .Insecure.User.country }},
    {{- end }}
    {{- if .Subject.Province }}
        "province": {{ toJson .Subject.Province }},
    {{- else }}
        "province": {{ toJson .Insecure.User.province }},
    {{- end }}
    {{- if .Subject.Locality }}
        "locality": {{ toJson .Subject.Locality }},
    {{- else }}
        "locality": {{ toJson .Insecure.User.locality }},
    {{- end }}
    {{- if .Subject.StreetAddress }}
        "streetAddress": {{ toJson .Subject.StreetAddress }},
    {{- else }}
        "streetAddress": {{ toJson .Insecure.User.streetAddress }},
    {{- end }}
    {{- if .Subject.PostalCode }}
        "postalCode": {{ toJson .Subject.PostalCode }},
    {{- else }}
        "postalCode": {{ toJson .Insecure.User.postalCode }},
    {{- end }}
    {{- if .Subject.CommonName }}
        "commonName": {{ toJson .Subject.CommonName }},
    {{- else }}
        "commonName": {{ toJson .Insecure.User.commonName }},
    {{- end }}
    {{- if .Subject.Organization }}
        "organization": {{ toJson .Subject.Organization }},
    {{- else }}
        "organization": {{ toJson .Insecure.User.organization }},
    {{- end }}
    {{- if .Subject.OrganizationalUnit }}
        "organizationalUnit": {{ toJson .Subject.OrganizationalUnit }}
    {{- else }}
        "organizationalUnit": {{ toJson .Insecure.User.organizationalUnit }}
    {{- end }}
  },
  "sans": {{ toJson .SANs }},
  {{- if .KeyUsage }}
    "keyUsage": {{ toJson .KeyUsage }},
  {{- else if .Insecure.User.keyUsage }}
    "keyUsage": {{ toJson .Insecure.User.keyUsage }},
  {{- else }}
    "keyUsage": ["digitalSignature"],
  {{- end }}
  {{- if .Principals }}
    "principals": {{ toJson .Principals }},
  {{- else if .Insecure.User.principals }}
    "principals": {{ toJson .Insecure.User.principals }},
  {{- end }}
  "crlDistributionPoints": [
    "http://ca.docker.vpn.${DOMAIN}/1.0/crl"
  ],
{{- if .ExtKeyUsage }}
  "extKeyUsage": {{ toJson .ExtKeyUsage }},
{{- else if .Insecure.User.extKeyUsage }}
  "extKeyUsage": {{ toJson .Insecure.User.extKeyUsage }},
{{- end }}
  "basicConstraints": {
    {{- if .BasicConstraints.IsCA }}
      "isCA": {{ toJson .BasicConstraints.IsCA }},
    {{- else if .Insecure.User.isCA }}
      "isCA": {{ toJson .Insecure.User.isCA }},
    {{- else }}
      "isCA": false,
    {{- end }}
    {{- if .BasicConstraints.MaxPathLen }}
      "maxPathLen": {{ toJson .BasicConstraints.MaxPathLen }}
    {{- else if .Insecure.User.maxPathLen }}
      "maxPathLen": {{ toJson .Insecure.User.maxPathLen }}
    {{- else }}
      "maxPathLen": 0
    {{- end }}
  }
}
EOF
#   {{- if .NotBefore }}
#     "notBefore": {{ toJson .NotBefore }},
#   {{- else if .Insecure.User.notBefore }}
#     "notBefore": {{ toJson .Insecure.User.notBefore }},
#   {{- else }}
#     "notBefore": "0s",
#   {{- end }}
#   {{- if .NotAfter }}
#     "notAfter": {{ toJson .NotAfter }}
#   {{- else if .Insecure.User.notAfter }}
#     "notAfter": {{ toJson .Insecure.User.notAfter }}
#   {{- else }}
#     "notAfter": "10y"
#   {{- end }}
    fi

    create_data_file "${DOMAIN}" "sign.orderer" '"Orderer"' '["digitalSignature"]'
    create_data_file "${DOMAIN}" "sign.peer" '"Peer"' '["digitalSignature"]'
    create_data_file "${DOMAIN}" "sign.user" '"Client"' '["digitalSignature"]'
    create_data_file "${DOMAIN}" "sign.admin" '"Admin"' '["digitalSignature"]'
    create_data_file "${DOMAIN}" "tls.server" '"Server"' '["digitalSignature", "keyEncipherment"]' '["serverAuth", "clientAuth"]'
    create_data_file "${DOMAIN}" "tls.client" '"Admin"' '["digitalSignature", "keyEncipherment"]' '["serverAuth", "clientAuth"]'
}

export -f create_certificate_template

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

#
# Generate orderer msp
#
function generate_orderer_msp() {
    local PROVISIONER_NAME
    local PROVISIONER_PASSWORD
    local DOMAIN
    local NAME

    PROVISIONER_NAME=$1
    PROVISIONER_PASSWORD=$2
    DOMAIN=$3
    NAME=$4

    generate_msp "${PROVISIONER_NAME}" "${PROVISIONER_PASSWORD}" "${DOMAIN}" "${NAME}" orderer
}

export -f generate_orderer_msp

#
# Generate peer msp
#
function generate_peer_msp() {
    local PROVISIONER_NAME
    local PROVISIONER_PASSWORD
    local DOMAIN
    local NAME

    PROVISIONER_NAME=$1
    PROVISIONER_PASSWORD=$2
    DOMAIN=$3
    NAME=$4

    generate_msp "${PROVISIONER_NAME}" "${PROVISIONER_PASSWORD}" "${DOMAIN}" "${NAME}" peer
}

export -f generate_peer_msp

#
# Generate user msp
#
function generate_user_msp() {
    local PROVISIONER_NAME
    local PROVISIONER_PASSWORD
    local DOMAIN
    local NAME
    local TYPE_PATH

    PROVISIONER_NAME=$1
    PROVISIONER_PASSWORD=$2
    DOMAIN=$3
    NAME=$4
    TYPE_PATH=$5

    generate_msp "${PROVISIONER_NAME}" "${PROVISIONER_PASSWORD}" "${DOMAIN}" "${NAME}" user "${TYPE_PATH}"
}

export -f generate_user_msp

#
# Generate Admin msp
#
function generate_admin_msp() {
    local PROVISIONER_NAME
    local PROVISIONER_PASSWORD
    local DOMAIN
    local TYPE_PATH

    PROVISIONER_NAME=$1
    PROVISIONER_PASSWORD=$2
    DOMAIN=$3
    TYPE_PATH=$4

    generate_user_msp "${PROVISIONER_NAME}" "${PROVISIONER_PASSWORD}" "${DOMAIN}" Admin "${TYPE_PATH}"
}

export -f generate_admin_msp

#
# Assign admin certificate to the domain msp
#
function assign_domain_admin_certificate() {
    local DOMAIN
    local TYPE_PATH
    local USER_NAME
    local DOMAIN_PATH
    local ADMIN_NAME
    local ADMIN_CERTIFICATE_PATH
    local MSP_DIR

    DOMAIN=$1
    TYPE_PATH=$2
    USER_NAME=$3

    # Set defaults if not provided
    if [ -z "${TYPE_PATH}" ]; then
        TYPE_PATH="peer"
    fi

    if [ -z "${USER_NAME}" ]; then
        USER_NAME="Admin"
    fi

    DOMAIN_PATH="${CERTS_DIR}/${TYPE_PATH}Organizations/vpn.${DOMAIN}"
    ADMIN_NAME="${USER_NAME}@vpn.${DOMAIN}"
    ADMIN_CERTIFICATE_PATH="${DOMAIN_PATH}/users/${ADMIN_NAME}/tls/client.crt"

    # Check if admin certificate exists
    if [ ! -f "${ADMIN_CERTIFICATE_PATH}" ]; then
        error "Admin certificate not found for ${ADMIN_NAME} in ${ADMIN_CERTIFICATE_PATH}"
        return 1
    fi

    info "Using admin certificate: ${ADMIN_CERTIFICATE_PATH}"

    # Copy admin certificate to all MSP directories
    while IFS= read -r -d '' MSP_DIR; do
        local ADMIN_CERTS_DIR="${MSP_DIR}/admincerts"
        local TARGET_CERT="${ADMIN_CERTS_DIR}/${ADMIN_NAME}.crt"

        # Create admincerts directory if it doesn't exist
        mkdir -p "${ADMIN_CERTS_DIR}"

        # Copy the certificate
        if cp "${ADMIN_CERTIFICATE_PATH}" "${TARGET_CERT}"; then
            info "Assigned admin certificate to ${TARGET_CERT}"
        else
            error "Failed to assign admin certificate to ${TARGET_CERT}"
        fi
    done < <(find "${CERTS_DIR}"/*Organizations/vpn."${DOMAIN}" -type d -name "msp" -print0 | grep -v "/users/")
}

export -f assign_domain_admin_certificate

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

#
# Transform a text to a array
#
function transform_text_to_array() {
    local TEXT
    local SEPARATOR

    TEXT=$1
    SEPARATOR=$2

    # Transform the text to a array splitting by separator preserving spaces
    echo "${TEXT}" | tr "${SEPARATOR}" '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

#
# Find line number of the first line containing the value in a text
#
function find_line_number_of_value_in_text() {
    local VALUE
    local TEXT
    local LINE_NUMBER

    VALUE=$1
    TEXT=$2

    # find the line number of the first line containing the value in the text
    LINE_NUMBER=$(echo "${TEXT}" | grep -n "${VALUE}" | cut -d: -f1)

    # return the line number minus 1
    echo "$((LINE_NUMBER - 1))"
}

export -f find_line_number_of_value_in_text

#
# Replace or add Environment Variable
#
function replace_environment_variable_in_env() {
    local VAR_NAME
    local VAR_VALUE
    local FILE

    VAR_NAME=$1
    VAR_VALUE=$2
    FILE=$3

    grep -q "^${VAR_NAME}=" "${FILE}" && sed -i "s|^${VAR_NAME}=.*|${VAR_NAME}=${VAR_VALUE}|" "${FILE}" || echo "${VAR_NAME}=${VAR_VALUE}" >> "${FILE}"
}

export -f replace_environment_variable_in_env

#
# Replace a environment variable in a docker compose file
#
function replace_environment_variable_in_docker_compose_file() {
    local DOCKER_COMPOSE_FILE
    local SERVICE_NAME
    local ENVIRONMENT_VARIABLE
    local VALUE
    local ENVIRONMENT
    local INDEX

    DOCKER_COMPOSE_FILE=$1
    SERVICE_NAME=$2
    ENVIRONMENT_VARIABLE=$3
    VALUE=$4

    ENVIRONMENT="$(get_value_from_json_or_yaml "${DOCKER_COMPOSE_FILE}" ".services.\"${SERVICE_NAME}\".environment")"
    INDEX=$(find_line_number_of_value_in_text "${ENVIRONMENT_VARIABLE}" "${ENVIRONMENT}")

    # If the index is different from -1, replace the environment variable
    if [ "${INDEX}" != "-1" ]; then
        replace_field_values_in_json_or_yaml "${DOCKER_COMPOSE_FILE}" ".services.\"${SERVICE_NAME}\".environment[${INDEX}]" "${ENVIRONMENT_VARIABLE}=${VALUE}"
    else
        # Add the environment variable to the end of the environment array
        yq eval ".services.\"${SERVICE_NAME}\".environment += \"${ENVIRONMENT_VARIABLE}=${VALUE}\"" -i "${DOCKER_COMPOSE_FILE}"
    fi
}

export -f replace_environment_variable_in_docker_compose_file

#
# Get environment variable from a docker compose file
#
function get_environment_variable_from_docker_compose_file() {
    local DOCKER_COMPOSE_FILE
    local SERVICE_NAME
    local ENVIRONMENT_VARIABLE
    local ENVIRONMENT
    local INDEX
    local VALUE

    DOCKER_COMPOSE_FILE=$1
    SERVICE_NAME=$2
    ENVIRONMENT_VARIABLE=$3

    ENVIRONMENT="$(get_value_from_json_or_yaml "${DOCKER_COMPOSE_FILE}" ".services.\"${SERVICE_NAME}\".environment")"
    INDEX=$(find_line_number_of_value_in_text "${ENVIRONMENT_VARIABLE}" "${ENVIRONMENT}")

    # If the index is different from -1, return the environment variable
    if [ "${INDEX}" != "-1" ]; then
        VALUE=$(get_value_from_json_or_yaml "${DOCKER_COMPOSE_FILE}" ".services.\"${SERVICE_NAME}\".environment[${INDEX}]")

        echo "${VALUE}" | cut -d'=' -f2
    fi
}

export -f get_environment_variable_from_docker_compose_file

#
# Generate a certificate authority item for a ccp file
#
function generate_certificate_authority_item_for_ccp_file() {
    local PROFILE_ID
    local FABLO_TARGET_DIR
    local CONNECTION_PROFILE_FILE
    local ORGANIZATION
    local CERTIFICATE_AUTHORITIES
    local CERTIFICATE_AUTHORITY
    local CA_SERVER_CONFIG
    local CA_PORT
    local ENROLL_ID
    local ENROLL_SECRET
    local CA_HOST

    PROFILE_ID=$1

    FABLO_TARGET_DIR="${CURRENT_DIR}/fablo-target"
    CONNECTION_PROFILE_FILE="${FABLO_TARGET_DIR}/fabric-config/connection-profiles/connection-profile-${PROFILE_ID}.yaml"

    # Get the organization from the connection profile
    ORGANIZATION=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".client.organization")
    CERTIFICATE_AUTHORITIES=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".organizations.${ORGANIZATION}.certificateAuthorities[]")

    for CERTIFICATE_AUTHORITY in ${CERTIFICATE_AUTHORITIES}; do
        CA_HOST="$(echo "${CERTIFICATE_AUTHORITY}" | cut -d'.' -f2-)"
        CA_SERVER_CONFIG="${FABLO_TARGET_DIR}/fabric-config/fabric-ca-server-config/${CA_HOST}/fabric-ca-server-config.yaml"
        CA_PORT="$(get_value_from_json_or_yaml "${CA_SERVER_CONFIG}" ".port")"
        ENROLL_ID="$(get_value_from_json_or_yaml "${CA_SERVER_CONFIG}" ".registry.identities[0].name")"
        ENROLL_SECRET="$(get_value_from_json_or_yaml "${CA_SERVER_CONFIG}" ".registry.identities[0].pass")"

        echo "  ${CERTIFICATE_AUTHORITY}:"
        echo "    tlsCACerts:"
        echo "      path: /etc/firefly/organizations/${CA_HOST}/ca/${CERTIFICATE_AUTHORITY}-cert.pem"
        # echo "      path: /etc/firefly/organizations/${CA_HOST}/tlsca/tls${CERTIFICATE_AUTHORITY}-cert.pem"
        echo "    url: https://${CERTIFICATE_AUTHORITY}:${CA_PORT}"
        # echo "    grpcOptions:"
        # echo "      ssl-target-name-override: ${CERTIFICATE_AUTHORITY}"
        echo "    registrar:"
        echo "      enrollId: ${ENROLL_ID}"
        echo "      enrollSecret: ${ENROLL_SECRET}"
        # echo "    httpOptions:"
        # echo "      verify: false"
    done
}

export -f generate_certificate_authority_item_for_ccp_file

#
# Generate a matcher item for a ccp file
#
function generate_matcher_item_for_ccp_file() {
    local ADDRESS
    local HOST

    ADDRESS=$1

    HOST=$(echo "${ADDRESS}" | sed 's|^[^:]*://||' | cut -d':' -f1)

    echo "    - pattern: ${HOST}"
    echo "      urlSubstitutionExp: ${ADDRESS}"
    echo "      sslTargetOverrideUrlSubstitutionExp: ${HOST}"
    echo "      mappedHost: ${HOST}"
}

export -f generate_matcher_item_for_ccp_file

#
# Generate a certificate authority matcher item for a ccp file
#
function generate_certificate_authority_matcher_item_for_ccp_file() {
    local PROFILE_ID
    local FABLO_TARGET_DIR
    local CONNECTION_PROFILE_FILE
    local ORGANIZATION
    local CERTIFICATE_AUTHORITIES
    local CERTIFICATE_AUTHORITY
    local CA_SERVER_CONFIG
    local CA_PORT

    PROFILE_ID=$1

    FABLO_TARGET_DIR="${CURRENT_DIR}/fablo-target"
    CONNECTION_PROFILE_FILE="${FABLO_TARGET_DIR}/fabric-config/connection-profiles/connection-profile-${PROFILE_ID}.yaml"

    # Get the organization from the connection profile
    ORGANIZATION=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".client.organization")
    CERTIFICATE_AUTHORITIES=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".organizations.${ORGANIZATION}.certificateAuthorities[]")

    for CERTIFICATE_AUTHORITY in ${CERTIFICATE_AUTHORITIES}; do
        CA_SERVER_CONFIG="${FABLO_TARGET_DIR}/fabric-config/fabric-ca-server-config/${CERTIFICATE_AUTHORITY/#ca\./}/fabric-ca-server-config.yaml"
        CA_PORT="$(get_value_from_json_or_yaml "${CA_SERVER_CONFIG}" ".port")"

        generate_matcher_item_for_ccp_file "https://${CERTIFICATE_AUTHORITY}:${CA_PORT}"
    done
}

export -f generate_certificate_authority_matcher_item_for_ccp_file

#
# Generate a organization item for a ccp file
#
function generate_organization_item_for_ccp_file() {
    local PROFILE_ID
    local CONNECTION_PROFILE_FILE
    local ORGANIZATION
    local MSP_ID
    local CERTIFICATE_AUTHORITIES
    local CERTIFICATE_AUTHORITY
    local PEERS
    local PEER

    PROFILE_ID=$1

    FABLO_TARGET_DIR="${CURRENT_DIR}/fablo-target"
    CONNECTION_PROFILE_FILE="${FABLO_TARGET_DIR}/fabric-config/connection-profiles/connection-profile-${PROFILE_ID}.yaml"

    # Get the organization from the connection profile
    ORGANIZATION=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".client.organization")
    MSP_ID=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".organizations.${ORGANIZATION}.mspid")
    CERTIFICATE_AUTHORITIES=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".organizations.${ORGANIZATION}.certificateAuthorities[]")
    PEERS=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".organizations.${ORGANIZATION}.peers[] | select(. | contains(\"${PROFILE_ID}\"))")

    echo "  ${ORGANIZATION}:"
    echo "    certificateAuthorities:"

    for CERTIFICATE_AUTHORITY in ${CERTIFICATE_AUTHORITIES}; do
        echo "      - ${CERTIFICATE_AUTHORITY}"
    done

    echo "    cryptoPath: /tmp/${ORGANIZATION}/msp"
    echo "    mspid: ${MSP_ID}"
    echo "    peers:"

    for PEER in ${PEERS}; do
        echo "      - ${PEER}"
    done
}

export -f generate_organization_item_for_ccp_file

#
# Generate a channel item for a ccp file
#
function generate_channel_item_for_ccp_file() {
    local CHANNEL_NAME
    local CHANNEL_PROFILE_IDS
    local CHANNEL_PROFILE_ID
    local EXECUTE
    local FABLO_TARGET_DIR
    local CONNECTION_PROFILE_FILE
    local CONFIGTX_FILE
    local ORGANIZATION
    local PEERS
    local PEER
    local ORDERERS
    local ORDERER

    CHANNEL_NAME=$1

    FABLO_TARGET_DIR="${CURRENT_DIR}/fablo-target"
    CONFIGTX_FILE="${FABLO_TARGET_DIR}/fabric-config/configtx.yaml"

    PEERS=()

    # Remove the the last part of the channel name and split by - and set the environment variable as an array
    CHANNEL_PROFILE_IDS=$(echo "${CHANNEL_NAME}" | cut -d'-' -f1- | tr '-' '\n')

    for CHANNEL_PROFILE_ID in ${CHANNEL_PROFILE_IDS}; do
        CONNECTION_PROFILE_FILE="${FABLO_TARGET_DIR}/fabric-config/connection-profiles/connection-profile-${PROFILE_ID}.yaml"

        # Get the organization from the connection profile
        ORGANIZATION=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".client.organization")

        # Add the peers to the array
        for PEER in $(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".organizations.${ORGANIZATION}.peers[]"); do
            # Add only if the peer is not already in the array
            if ! echo "${PEERS[@]}" | grep -q "${PEER}"; then
                PEERS+=("${PEER}")
            fi
        done
    done

    # Get the orderers from the configtx file
    # ORDERERS=$(get_value_from_json_or_yaml "${CONFIGTX_FILE}" ".Orderer.Addresses[] | select(. | contains(\"${PROFILE_ID}\"))")
    ORDERERS=$(cat "${CONFIGTX_FILE}" | grep "        - " | grep orderers. | grep -v Host | yq .[])

    echo "  ${CHANNEL_NAME}:"
    # echo "    orderers:"

    # for ORDERER in ${ORDERERS}; do
    #     EXECUTE=false

    #     for CHANNEL_PROFILE_ID in ${CHANNEL_PROFILE_IDS}; do
    #         if echo "${ORDERER}" | grep "${CHANNEL_PROFILE_ID}"; then
    #             EXECUTE=true
    #             break
    #         fi
    #     done

    #     # Skip if the orderer does not contain the profile id
    #     if [ "${EXECUTE}" == false ]; then
    #         continue
    #     fi

    #     ORDERER_HOST=$(echo "${ORDERER}" | cut -d':' -f1)

    #     echo "      - ${ORDERER_HOST}"
    # done

    echo "    peers:"

    for PEER in "${PEERS[@]}"; do
        EXECUTE=false

        for CHANNEL_PROFILE_ID in ${CHANNEL_PROFILE_IDS}; do
            if echo "${PEER}" | grep "${CHANNEL_PROFILE_ID}" > /dev/null; then
                EXECUTE=true
                break
            fi
        done

        # Skip if the peer does not contain the profile id
        if [ "${EXECUTE}" == false ]; then
            continue
        fi

        echo "      ${PEER}:"
        echo "        chaincodeQuery: true"
        echo "        endorsingPeer: true"
        echo "        eventSource: true"
        echo "        ledgerQuery: true"
    done
}

export -f generate_channel_item_for_ccp_file

#
# Generate a ccp file for a given domain
#
function generate_ccp_file_from_fablo_target() {
    local PROFILE_ID
    local ADITIONAL_PROFILE_ID
    local FABLO_TARGET_DIR
    local FABLO_CONFIG_FILE
    local CONNECTION_PROFILE_FILE
    local CONFIGTX_FILE
    local DOCKER_COMPOSE_FILE
    local CHANNEL_NAMES
    local CHANNEL_NAME
    local CCP_FILE
    local ORGANIZATION
    local PEERS
    local PEER
    local CORE_PEER_ADDRESS
    local ORDERERS
    local ORDERER
    local ORDERER_HOST
    local CA_HOST

    PROFILE_ID=$1
    ADITIONAL_PROFILE_ID=$2

    FIREFLY_HOME="${FIREFLY_HOME:-${CURRENT_DIR:-${HOME}}/.firefly}"
    CCP_FILE="${FIREFLY_HOME}/${PROFILE_ID}-ccp.yaml"

    FABLO_TARGET_DIR="${CURRENT_DIR}/fablo-target"
    FABLO_CONFIG_FILE="${CURRENT_DIR}/fablo-config.yaml"
    CONNECTION_PROFILE_FILE="${FABLO_TARGET_DIR}/fabric-config/connection-profiles/connection-profile-${PROFILE_ID}.yaml"
    CONFIGTX_FILE="${FABLO_TARGET_DIR}/fabric-config/configtx.yaml"
    DOCKER_COMPOSE_FILE="${FABLO_TARGET_DIR}/fabric-docker/docker-compose.yaml"

    # Get the channel names from the fablo config file
    CHANNEL_NAMES=$(get_value_from_json_or_yaml "${FABLO_CONFIG_FILE}" ".channels[].name")

    # Get the organization from the connection profile
    ORGANIZATION=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".client.organization")
    PEERS=$(get_value_from_json_or_yaml "${CONNECTION_PROFILE_FILE}" ".organizations.${ORGANIZATION}.peers[]")

    # Get the orderers from the configtx file
    # ORDERERS=$(get_value_from_json_or_yaml "${CONFIGTX_FILE}" ".Orderer.Addresses[] | select(. | contains(\"${PROFILE_ID}\"))")
    # ORDERERS=$(get_value_from_json_or_yaml fablo-target/fabric-config/configtx.yaml ".Orderers[].EtcdRaft.Consenters[].Host | select(. | contains(\"${PROFILE_ID}\"))")
    ORDERERS=$(get_value_from_json_or_yaml fablo-target/fabric-config/configtx.yaml ".Orderers[].EtcdRaft.Consenters[].Host")

    {
        echo "certificateAuthorities:"

        generate_certificate_authority_item_for_ccp_file "${PROFILE_ID}"
        generate_certificate_authority_item_for_ccp_file "${ADITIONAL_PROFILE_ID}"

        echo "channels:"

        for CHANNEL_NAME in ${CHANNEL_NAMES}; do
            # Skip if the channel name not contains the profile id
            if ! echo "${CHANNEL_NAME}" | grep -q "${PROFILE_ID}"; then
                continue
            fi

            generate_channel_item_for_ccp_file "${CHANNEL_NAME}"
        done

        echo "client:"
        echo "  BCCSP:"
        echo "    security:"
        echo "      default:"
        echo "        provider: SW"
        echo "      enabled: true"
        echo "      hashAlgorithm: SHA2"
        echo "      level: 256"
        echo "      softVerify: true"
        echo "  credentialStore:"
        echo "    cryptoStore:"
        echo "      path: /etc/firefly/organizations/fabric.vpn.${PROFILE_ID}.com.br/msp"
        echo "    path: /etc/firefly/organizations/fabric.vpn.${PROFILE_ID}.com.br/msp"
        echo "  cryptoconfig:"
        echo "    path: /etc/firefly/organizations/fabric.vpn.${PROFILE_ID}.com.br/msp"
        echo "  logging:"
        echo "    level: debug"
        echo "  organization: ${ORGANIZATION}"
        echo "  tlsCerts:"
        echo "    client:"
        echo "      cert:"
        echo "        path: /etc/firefly/organizations/fabric.vpn.${PROFILE_ID}.com.br/users/Admin@fabric.vpn.${PROFILE_ID}.com.br/msp/signcerts/Admin@fabric.vpn.${PROFILE_ID}.com.br-cert.pem"
        echo "      key:"
        echo "        path: /etc/firefly/organizations/fabric.vpn.${PROFILE_ID}.com.br/users/Admin@fabric.vpn.${PROFILE_ID}.com.br/msp/keystore/priv-key.pem"
        echo "orderers:"

        for ORDERER in ${ORDERERS}; do
            # # Skip if the orderer does not contain the profile id
            # if ! echo "${ORDERER}" | grep -q "${PROFILE_ID}"; then
            #     continue
            # fi

            ORDERER_HOST=$(echo "${ORDERER}" | cut -d':' -f1)
            # Remove the first part of the host
            CA_HOST=$(echo "${ORDERER_HOST}" | cut -d'.' -f3-)

            echo "  ${ORDERER_HOST}:"
            echo "    tlsCACerts:"
            echo "      path: /etc/firefly/organizations/${CA_HOST}/peers/${ORDERER_HOST}/msp/tlscacerts/tlsca.${CA_HOST}-cert.pem"
            echo "    url: grpcs://${ORDERER}"
        done

        echo "organizations:"

        generate_organization_item_for_ccp_file "${PROFILE_ID}"
        generate_organization_item_for_ccp_file "${ADITIONAL_PROFILE_ID}"

        echo "peers:"

        for PEER in ${PEERS}; do
            # Skip if the peer does not contain the profile id
            if ! echo "${PEER}" | grep -q "${PROFILE_ID}"; then
                continue
            fi

            CORE_PEER_ADDRESS=$(get_environment_variable_from_docker_compose_file "${DOCKER_COMPOSE_FILE}" "${PEER}" "CORE_PEER_ADDRESS")
            CA_HOST=$(echo "${PEER}" | cut -d'.' -f2-)

            echo "  ${PEER}:"
            echo "    tlsCACerts:"
            echo "      path: /etc/firefly/organizations/${CA_HOST}/peers/${PEER}/tls/ca.crt"
            echo "    url: grpcs://${CORE_PEER_ADDRESS}"
        done

        echo "version: 1.1.0%"
        echo ""
        echo "entityMatchers:"
        echo "  peer:"

        for PEER in ${PEERS}; do
            # Skip if the peer does not contain the profile id
            if ! echo "${PEER}" | grep -q "${PROFILE_ID}"; then
                continue
            fi

            CORE_PEER_ADDRESS=$(get_environment_variable_from_docker_compose_file "${DOCKER_COMPOSE_FILE}" "${PEER}" "CORE_PEER_ADDRESS")

            generate_matcher_item_for_ccp_file "${CORE_PEER_ADDRESS}"
        done

        echo "  orderer:"

        for ORDERER in ${ORDERERS}; do
            generate_matcher_item_for_ccp_file "${ORDERER}"
        done

        echo "  certificateAuthority:"

        generate_certificate_authority_matcher_item_for_ccp_file "${PROFILE_ID}"
        generate_certificate_authority_matcher_item_for_ccp_file "${ADITIONAL_PROFILE_ID}"
    } > "${CCP_FILE}"
}

export -f generate_ccp_file_from_fablo_target

#
# Run specify
#
function run_specify() {
    local ARGUMENTS

    ARGUMENTS=()

    if [ $# -eq 0 ]; then
        ARGUMENTS+=("init" "--here" "--script" "sh" "--ai" "windsurf" "--force")
    else
        ARGUMENTS+=("$@")
    fi

    uvx --refresh --upgrade --no-cache --from "git+https://github.com/github/spec-kit" specify "${ARGUMENTS[@]}"
}

export -f run_specify

#
# Print a table line
#
function print_table_line() {
    local COLLS_WIDTH
    local COLLS_COUNT
    local ROW
    local I

    COLLS_WIDTH=("$@")
    COLLS_COUNT=${#COLLS_WIDTH[@]}


    ROW="+"

    for ((I=0; I<COLLS_COUNT; I++)); do
        # Add a string with cell width repetitions of "-" to the row
        ROW+="$(printf "%-$((COLLS_WIDTH[I]+2))s" "-" | sed 's/ /-/g')"
        ROW+="+"
    done

    echo "${ROW}"
}

export -f print_table_line

#
# Print a table separator line
#
function print_table_separator_line() {
    local COLLS_WIDTH
    local COLLS_COUNT
    local ROW
    local I

    COLLS_WIDTH=("$@")
    COLLS_COUNT=${#COLLS_WIDTH[@]}


    ROW="+"

    for ((I=0; I<COLLS_COUNT; I++)); do
        # Add a string with cell width repetitions of "-" to the row
        ROW+="\033[90m$(printf "%-$((COLLS_WIDTH[I]+2))s" "-" | sed 's/ /-/g')\033[0m"
        ROW+="+"
    done

    echo -e "${ROW}"
}

export -f print_table_separator_line

#
# This function prints a table with the given columns and rows drawing lines between columns and around the table.
# The first argument is the count of columns, the next arguments are the color of each column, the next arguments are the headers of the table and the rest of the arguments are the content of the table.
#
# Example:
# print_table "3" "\033[90m" "\033[94m" "\033[92m" "Col 1" "C2" "Column 3" "Row 1" "Row 2" "Row 3" " " " " " " "Row 4" "Row 5" "Row 6" "-" "-" "-" "Row 7" "Row 8" "Row 9"
#
# Output:
# +----------+----------+----------+
# |   Col 1  |    C2    | Column 3 |
# +----------+----------+----------+
# | Row 1    | Row 2    | Row 3    |
# |          |          |          |
# | Row 4    | Row 5    | Row 6    |
# +----------+----------+----------+
# | Row 7    | Row 8    | Row 9    |
# +----------+----------+----------+
#
function print_table() {
    local COLUMN_COUNT
    local HEADERS
    local COLORS
    local DATA
    local COLUMN_WIDTHS
    local MAX_WIDTH
    local I
    local J
    local CELL_WIDTH
    local HEADER_ROW
    local DATA_ROW

    # First argument is the number of columns
    COLUMN_COUNT=$1
    shift

    # Next arguments are colors
    COLORS=()
    for ((I=0; I<COLUMN_COUNT; I++)); do
        COLORS+=("$1")
        shift
    done

    # Next arguments are headers
    HEADERS=()
    for ((I=0; I<COLUMN_COUNT; I++)); do
        HEADERS+=("$1")
        shift
    done

    # Remaining arguments are data
    DATA=("$@")

    # Calculate column widths
    COLUMN_WIDTHS=()
    for ((I=0; I<COLUMN_COUNT; I++)); do
        MAX_WIDTH=${#HEADERS[I]}

        # Check data cells for this column
        for ((J=I; J<${#DATA[@]}; J+=COLUMN_COUNT)); do
            CELL_WIDTH=${#DATA[J]}
            if [ "${CELL_WIDTH}" -gt "${MAX_WIDTH}" ]; then
                MAX_WIDTH="${CELL_WIDTH}"
            fi
        done

        # Store the column width
        COLUMN_WIDTHS+=("${MAX_WIDTH}")
    done

    # Print top border
    print_table_line "${COLUMN_WIDTHS[@]}"

    # Print header row
    HEADER_ROW="|"
    for ((I=0; I<COLUMN_COUNT; I++)); do
        # Calculate padding for centering
        HEADER_LENGTH=${#HEADERS[I]}
        TOTAL_WIDTH=${COLUMN_WIDTHS[I]}
        LEFT_PAD=$(( (TOTAL_WIDTH - HEADER_LENGTH) / 2 ))
        RIGHT_PAD=$(( TOTAL_WIDTH - HEADER_LENGTH - LEFT_PAD ))

        # Create centered header with padding
        CENTERED_HEADER="$(printf "%*s%s%*s" ${LEFT_PAD} "" "${HEADERS[I]}" ${RIGHT_PAD} "")"
        HEADER_ROW+=" \033[1m${CENTERED_HEADER}\033[0m |"
    done
    echo -e "${HEADER_ROW}"

    # Print separator line after header
    print_table_line "${COLUMN_WIDTHS[@]}"

    # Print data rows
    for ((I=0; I<${#DATA[@]}; I+=COLUMN_COUNT)); do
        # Check if this row is a separator row (all cells contain "-")
        IS_SEPARATOR=true
        for ((J=0; J<COLUMN_COUNT; J++)); do
            if [ "${DATA[I+J]}" != "-" ]; then
                IS_SEPARATOR=false
                break
            fi
        done

        if [ "${IS_SEPARATOR}" = true ]; then
            # Print separator line
            print_table_separator_line "${COLUMN_WIDTHS[@]}"
        else
            # Print normal data row
            DATA_ROW="|"
            for ((J=0; J<COLUMN_COUNT; J++)); do
                DATA_ROW+=" ${COLORS[J]}$(printf "%-${COLUMN_WIDTHS[J]}s" "${DATA[I+J]}")\033[0m |"
            done
            echo -e "${DATA_ROW}"
        fi
    done

    # Print bottom border
    print_table_line "${COLUMN_WIDTHS[@]}"
}

export -f print_table

#
# Execute on super devcontainer
#
function execute_on_super() {
    local CONTAINER_ID
    local DOCKER_EXEC_OPTS

    CONTAINER_ID="$(docker ps --filter "label=devcontainer.local_folder" --format "{{.ID}}\t{{.Label \"devcontainer.local_folder\"}}" | awk '/production-manager/ {print $1}' | while read -r id; do [ "$(docker exec "${id}" hostname 2>/dev/null)" != "$(hostname)" ] && echo "${id}"; done)"

    if [ -n "${CONTAINER_ID}" ]; then
        DOCKER_EXEC_OPTS=(-i)

        if [ -t 0 ] && [ -t 1 ]; then
            DOCKER_EXEC_OPTS+=(-t)
        fi

        # Execute the command on the super devcontainer using `/workspaces/production-manager` as working directory and with vscode as user and group
        docker exec "${DOCKER_EXEC_OPTS[@]}" -w /workspaces/production-manager --user vscode "${CONTAINER_ID}" env TERM="${TERM:-xterm}" "$@"
    else
        error "Super devcontainer is not running."
        return 1
    fi
}

export -f execute_on_super


#
# Execute this script on super devcontainer
#
function super_this() {
    local SCRIPT_PATH

    SCRIPT_PATH=scripts/this.sh

    execute_on_super ${SCRIPT_PATH} "$@"
}

export -f super_this
