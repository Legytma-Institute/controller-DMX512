#!/usr/bin/env bash

function create_directory() {
    local DIRECTORY=$1
    local OWNER=$2
    local PERMISSIONS=$3

    if [ ! -d "${DIRECTORY}" ]; then
        sudo mkdir -p ${DIRECTORY}

        if [ ! -z "${OWNER}" ]; then
            sudo chown -R ${OWNER} ${DIRECTORY}
        fi

        if [ ! -z "${PERMISSIONS}" ]; then
            sudo chmod -R ${PERMISSIONS} ${DIRECTORY}
        fi
    fi
}

export -f create_directory
