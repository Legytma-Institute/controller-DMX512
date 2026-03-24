#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../infrastructure/docker/count_services_state.sh"

# Wait services to be passed state
function wait_services_to_be() {
    local PROPERTY=$1
    local DESIRED_STATE=$2
    local STATE_COUNT=$3
    local TIMEOUT=$4
    shift 4

    local STATE=$(count_services_state ${PROPERTY} ${DESIRED_STATE} $@)
    local TIMEOUT_COUNT=0

    while [[ ${STATE} != "${STATE_COUNT}" ]]; do
        TIMEOUT_COUNT=$((TIMEOUT_COUNT+1))

        if [[ ${TIMEOUT_COUNT} -gt ${TIMEOUT} ]]; then
            echo "Timed out waiting for services to start: $((${STATE_COUNT} - ${STATE}))"

            exit 1
        fi

        echo "${TIMEOUT_COUNT} waiting for $((${STATE_COUNT} - ${STATE})) services to start..."
        sleep 1
        STATE=$(count_services_state ${PROPERTY} ${DESIRED_STATE} $@)
    done
}

export -f wait_services_to_be
