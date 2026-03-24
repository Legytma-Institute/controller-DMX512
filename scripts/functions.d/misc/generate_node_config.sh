#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../setup/installation/install_packages.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../setup/installation/install_docker.sh"

function generate_node_config() {
    local NODE_PATH=$1
    local HTTP_PORT=$2
    local P2P_HOST=$3
    local P2P_PORT=$4
    local BESU_URL=$5

    local NODE_CONFIG_PATH=$NODE_PATH/cfg.toml

    echo "# NODE Config File" > $NODE_CONFIG_PATH
    echo 'data-path="data"' >> $NODE_CONFIG_PATH

    if [ -z "$BESU_URL" ]; then
        echo 'network="dev"' >> $NODE_CONFIG_PATH
        echo 'miner-enabled=true' >> $NODE_CONFIG_PATH
        echo 'miner-coinbase="0xfe3b557e8fb62b89f4916b721be55ceb828dbd73"' >> $NODE_CONFIG_PATH
    fi

    echo "" >> $NODE_CONFIG_PATH

    echo '# Chain' >> $NODE_CONFIG_PATH
    echo 'genesis-file="../genesis.json"' >> $NODE_CONFIG_PATH
    echo "" >> $NODE_CONFIG_PATH

    echo '# RPC' >> $NODE_CONFIG_PATH
    echo 'rpc-http-enabled=true' >> $NODE_CONFIG_PATH
    echo 'rpc-http-api=["DEBUG","ETH", "ADMIN", "WEB3", "QBFT", "NET", "EEA", "PRIV", "PERM","TXPOOL","PLUGINS","MINER","TRACE"]' >> $NODE_CONFIG_PATH
    echo 'rpc-http-cors-origins=["all"]' >> $NODE_CONFIG_PATH
    echo 'rpc-http-host="0.0.0.0"' >> $NODE_CONFIG_PATH
    echo "rpc-http-port=$HTTP_PORT" >> $NODE_CONFIG_PATH
    echo "" >> $NODE_CONFIG_PATH

    echo '# p2p' >> $NODE_CONFIG_PATH
    echo 'p2p-enabled=true' >> $NODE_CONFIG_PATH
    echo "p2p-host=\"$P2P_HOST\"" >> $NODE_CONFIG_PATH
    echo "p2p-port=\"$P2P_PORT\"" >> $NODE_CONFIG_PATH
    echo 'p2p-interface="0.0.0.0"' >> $NODE_CONFIG_PATH
    echo 'nat-method="AUTO"' >> $NODE_CONFIG_PATH

    echo "" >> $NODE_CONFIG_PATH

    if [ ! -z "$BESU_URL" ]; then
        install_packages jq
        install_docker

        local RESPONSE=$(docker run --rm --network rede_besu alpine/curl:latest -s -X POST --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' $BESU_URL)
        local ENODE_ADDRESS=$(echo $RESPONSE | jq -r '.result.enode')

        echo "# Bootnodes" >> $NODE_CONFIG_PATH
        echo 'bootnodes=["'$ENODE_ADDRESS'"]' >> $NODE_CONFIG_PATH
    fi

    echo "" >> $NODE_CONFIG_PATH

    #echo '# Plugin DINAMO' >> $NODE_CONFIG_PATH
    #echo 'security-module="dinamo"' >> $NODE_CONFIG_PATH

    #cat $NODE_CONFIG_PATH
}

export -f generate_node_config
