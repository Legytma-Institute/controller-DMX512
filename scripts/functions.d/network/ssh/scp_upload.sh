#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ssh_rsync.sh"

function scp_upload() {
    local SOURCE=$1
    local DESTINATION=$2

    echo "Uploading ${SOURCE}/* to ${SSH_USER}@${SSH_HOST}:/tmp${DESTINATION}..."

    # Copy SOURCE to DESTINATION
    if [ -d "${SOURCE}" ]; then
        scp -r -C -p -q -P ${SSH_PORT} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${SOURCE}/* "${SSH_USER}@${SSH_HOST}:/tmp${DESTINATION}" || exit 1

        sleep 0.5

        ssh_rsync "/tmp${DESTINATION}/*" "${DESTINATION}"
    fi
}

export -f scp_upload
