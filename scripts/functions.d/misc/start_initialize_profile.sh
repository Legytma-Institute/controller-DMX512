#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../network/ssh/wait_ssh_server.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../network/ssh/ssh_run.sh"

function start_initialize_profile() {
    # Run containers on initialize profile
    docker compose --profile initialize up -d --build --pull ${PULL_POLICY:-always} --remove-orphans openssh-server || exit 1

    wait_ssh_server 60

    ssh_run "sudo apk --update add rsync" || exit 1
}

export -f start_initialize_profile
