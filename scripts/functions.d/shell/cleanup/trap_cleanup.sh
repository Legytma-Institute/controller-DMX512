#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../logging/stdout/debug.sh"

    # debug "Vendorizing firefly-go..."
    # pushd "${FIREFLY_HOME}/firefly/smart_contracts/fabric/firefly-go"

    # GOWORK=off GO111MODULE=on go mod vendor

    # popd

    trap_cleanup() {
        pushd "${CURRENT_DIR}/fablo-target/fabric-docker"

        docker compose logs peer0.fabric.vpn.legytma.com.br > "${CURRENT_DIR}/peer0.fabric.vpn.legytma.com.br.log"

        popd

        if [ -f "${CURRENT_DIR}/chaincodes/production-manager/.npmrc" ]; then
            if grep -q "//npm.pkg.github.com/:_authToken=" "${CURRENT_DIR}/chaincodes/production-manager/.npmrc"; then
                # Remove existing line
                sed -i -E "/\/\/npm.pkg.github.com\/:_authToken=/d" "${CURRENT_DIR}/chaincodes/production-manager/.npmrc"
            fi
        fi
    }

export -f trap_cleanup
