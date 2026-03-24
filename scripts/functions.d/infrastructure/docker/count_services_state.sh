#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../setup/installation/install_docker.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../setup/installation/install_packages.sh"

# Count docker compose service status
function count_services_state() {
    local PROPERTY=$1
    local FILTER=$2
    shift 2

    install_docker
    install_packages jq

    docker compose ps --format json $@ | jq -s ".[] | .${PROPERTY}" | grep -c ${FILTER}
}

export -f count_services_state
