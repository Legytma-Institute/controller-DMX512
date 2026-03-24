#!/usr/bin/env bash

# Wait services to be passed state
function wait_ssh_server() {
    local TIMEOUT=$1

    local STATE=$(ssh -2 -C -n -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p ${SSH_PORT} ${SSH_USER}@${SSH_HOST} ls 2>/dev/null | grep sshd.pid)
    local TIMEOUT_COUNT=0

    while [[ ${STATE} != "sshd.pid" ]]; do
        TIMEOUT_COUNT=$((TIMEOUT_COUNT+1))

        if [[ ${TIMEOUT_COUNT} -gt ${TIMEOUT} ]]; then
            echo "Timed out waiting for SSH Server to be ready!"

            exit 1
        fi

        echo "${TIMEOUT_COUNT} waiting for SSH Server to be ready..."
        sleep 1
        STATE=$(ssh -2 -C -n -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p ${SSH_PORT} ${SSH_USER}@${SSH_HOST} ls 2>/dev/null | grep sshd.pid)
    done

    echo "SSH Server is ready!"

    sleep 0.5
}

export -f wait_ssh_server
