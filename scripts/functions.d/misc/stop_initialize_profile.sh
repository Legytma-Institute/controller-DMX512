#!/usr/bin/env bash

function stop_initialize_profile() {
    # Stop containers on initialize profile
    docker compose --profile initialize down openssh-server || exit 1
}

export -f stop_initialize_profile
