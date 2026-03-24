#!/usr/bin/env bash

function rsync_copy() {
    local SOURCE=$1
    local DESTINATION=$2
    local PERMISSIONS=$3

    # Copy SOURCE to DESTINATION
    if [ ! -z "$(sudo ls -A ${SOURCE})" ]; then
        echo "Copying ${SOURCE} to ${DESTINATION}..."

        sudo rsync -vrczu ${SOURCE} ${DESTINATION} || exit 1

        if [ ! -z "${PERMISSIONS}" ]; then
            sudo chown -R ${PERMISSIONS} ${DESTINATION}
        fi
    fi
}

export -f rsync_copy
