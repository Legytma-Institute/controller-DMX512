#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../setup/installation/install_docker.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../logging/stderr/error.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../misc/generate_node_config.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../infrastructure/docker/run_and_check_services.sh"

function generate_blockchain_config() {
    local DATA_PATH=$1
    local NETWORK_FILES_PATH=$2

    # Define o caminho principal para as pastas com as chaves
    local DIRECTORY="$DATA_PATH/$NETWORK_FILES_PATH/keys"

    if [ ! -d "$DIRECTORY" ]; then
        install_docker

        docker run --rm -v ./$DATA_PATH:/data -w /data hyperledger/besu:latest operator generate-blockchain-config --config-file=qbftConfigFile.json --to=$NETWORK_FILES_PATH --private-key-file-name=key

        # Verifica se o caminho realmente existe
        if [ ! -d "$DIRECTORY" ]; then
            echo "error: Directory '$DIRECTORY' does not exist."
            exit 1
        fi

        local N_INDEX=0
        local HTTP_PORT=8545
        local SUFFIX_IP=11
        local P2P_PORT=30303

        local BESU_URL=""

        # Faz a iteração na pasta e busca os nomes de todas elas
        for folder in "$DIRECTORY"/*/; do
            N_INDEX=$((N_INDEX+1))

            local NODE_PATH="$DIRECTORY/node$N_INDEX"

            mkdir -p "$NODE_PATH"

            mv "$folder" "$NODE_PATH/data"

            generate_node_config $NODE_PATH $HTTP_PORT $DOCKER_BASE_IP.$SUFFIX_IP $P2P_PORT $BESU_URL

            HTTP_PORT=$((HTTP_PORT+1))
            SUFFIX_IP=$((SUFFIX_IP+1))
            P2P_PORT=$((P2P_PORT+1))

            run_and_check_services 1 30 node$N_INDEX

            if [ -z "$BESU_URL" ]; then
                BESU_URL="http://$DOCKER_BASE_IP.$SUFFIX_IP:$HTTP_PORT"
            fi
        done
    fi
}

export -f generate_blockchain_config
