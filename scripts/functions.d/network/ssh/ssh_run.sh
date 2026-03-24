#!/usr/bin/env bash

function ssh_run() {
    local COMMAND=$1
    local QUIET=$2

    if [ "${QUIET}" != "-q" ]; then
        echo "Running ${COMMAND}..."
    fi

    # Run the command with sudo
    ssh -2 -C -n -T -p ${SSH_PORT} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${SSH_USER}@${SSH_HOST}" "${COMMAND}" 2>/dev/null || exit 1

    sleep 0.5
}

export -f ssh_run
