#!/usr/bin/env bash

function ssh_base_run() {
    local COMMAND=$1
    local QUIET=$2

    if [ "${QUIET}" != "-q" ]; then
        echo "Running ${COMMAND}..."
    fi

    # Run the command with sudo
    ssh -2 -C -n -T -p ${SSH_BASE_PORT} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${SSH_BASE_USER}@${SSH_BASE_HOST}" "${COMMAND}" 2>/dev/null || exit 1

    sleep 0.5
}

export -f ssh_base_run
