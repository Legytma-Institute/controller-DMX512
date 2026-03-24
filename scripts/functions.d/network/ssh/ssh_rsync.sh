#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ssh_run.sh"

function ssh_rsync() {
    local SOURCE=$1
    local DESTINATION=$2

    echo "Moving ${SOURCE} to ${DESTINATION}..."

    # Move the files to the final destination with sudo
    ssh_run "sudo rsync -vrczu ${SOURCE} ${DESTINATION}" || exit 1
}

export -f ssh_rsync
