#!/usr/bin/env bash

#
# FIXME: Remove this after the issue is fixed
# Restart explorer services to bypass the initial state problem
# when the explorer is not ready yet
#
fix_hyperledger_explorer_start() {
    pushd "${CURRENT_DIR}/fablo-target/fabric-docker"
    docker compose restart explorer.*
    popd
}

export -f fix_hyperledger_explorer_start
