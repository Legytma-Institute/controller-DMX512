#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../network/http/get_latest_version.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../shell/logging/debug.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install_packages.sh"

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
