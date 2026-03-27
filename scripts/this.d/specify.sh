#!/usr/bin/env bash
# @description Initialize a new spec-kit repository passing arguments to the specify command
# @require debug run_specify info error

set -euo pipefail

SPECIFY_ARGUMENTS=("$@")

debug "Running specify..."

if run_specify "${SPECIFY_ARGUMENTS[@]}"; then
    info "Specify succeeded"
else
    error "Specify failed"
    exit 1
fi
