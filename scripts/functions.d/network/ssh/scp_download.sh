#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ssh_run.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../shell/files/rsync_copy.sh"

function scp_download() {
    local SOURCE=$1
    local DESTINATION=$2

    echo "Downloading ${SSH_USER}@${SSH_HOST}:/tmp${SOURCE}/* to ${DESTINATION}..."

    # Copy SOURCE to DESTINATION
    if [ ! -z "$(ssh_run "$(typeset -f rsync_copy); rsync_copy \"${SOURCE}/*\" \"/tmp${SOURCE}\" \"1000:1000\"" -q)" ]; then
        scp -r -C -p -q -P ${SSH_PORT} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${SSH_USER}@${SSH_HOST}:/tmp${SOURCE}/*" ${DESTINATION} 2>/dev/null || exit 1
    fi
}

export -f scp_download
