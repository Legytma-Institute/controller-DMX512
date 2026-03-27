#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../shell/logging/error.sh"

#
# Execute on super devcontainer
#
function execute_on_super() {
    local CONTAINER_ID
    local DOCKER_EXEC_OPTS

    CONTAINER_ID="$(docker ps --filter "label=devcontainer.local_folder" --format "{{.ID}}\t{{.Label \"devcontainer.local_folder\"}}" | awk '/production-manager/ {print $1}' | while read -r id; do [ "$(docker exec "${id}" hostname 2>/dev/null)" != "$(hostname)" ] && echo "${id}"; done)"

    if [ -n "${CONTAINER_ID}" ]; then
        DOCKER_EXEC_OPTS=(-i)

        if [ -t 0 ] && [ -t 1 ]; then
            DOCKER_EXEC_OPTS+=(-t)
        fi

        # Execute the command on the super devcontainer using `/workspaces/production-manager` as working directory and with vscode as user and group
        docker exec "${DOCKER_EXEC_OPTS[@]}" -w /workspaces/production-manager --user vscode "${CONTAINER_ID}" env TERM="${TERM:-xterm}" "$@"
    else
        error "Super devcontainer is not running."
        return 1
    fi
}

export -f execute_on_super
