#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../setup/installation/install_docker.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../network/wait/wait_services_to_be.sh"

# Run and check services
function run_and_check_services() {
    local STATE_COUNT=$1
    local TIMEOUT=$2
    # HEALTHY=$3
    shift 2

    install_docker

    echo "Starting $@..."
    docker compose up -d --build --pull ${PULL_POLICY:-always} --remove-orphans $@ || exit 1

    wait_services_to_be 'State' 'running' ${STATE_COUNT} ${TIMEOUT} $@ || exit 1

    echo "$@ running!"

    # if [ "$HEALTHY" == "true" ]; then
        wait_services_to_be 'Status' '(healthy)' ${STATE_COUNT} ${TIMEOUT} $@ || exit 1

        echo "$@ healthy!"
    # fi
}

export -f run_and_check_services
