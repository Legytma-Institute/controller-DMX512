#!/usr/bin/env bash
# @description Run the application (dmx-controller)
# @require ensure_dev_dependencies debug info error

set -euo pipefail

RUN_ARGUMENTS=()

DEBUG=false

while [[ $# -gt 0 ]]; do
    case "${1:-}" in
        --debug)
            DEBUG=true
            shift 1
            ;;
        *)
            RUN_ARGUMENTS+=("$1")
            shift 1
            ;;
    esac
done

debug "Running app..."

if [ "${DEBUG}" == "true" ]; then
    if "${VENV_PY}" -m controller_dmx512.main "${RUN_ARGUMENTS[@]}"; then
        info "Run succeeded!"
        exit 0
    else
        error "Run failed!"
        exit 1
    fi
fi

ensure_dev_dependencies

if [ -x "${VENV_DIR}/bin/dmx-controller" ]; then
    if "${VENV_DIR}/bin/dmx-controller" "${RUN_ARGUMENTS[@]}"; then
        info "Run succeeded!"
    else
        error "Run failed!"
        exit 2
    fi
else
    if "${VENV_PY}" -m controller_dmx512.main "${RUN_ARGUMENTS[@]}"; then
        info "Run succeeded!"
    else
        error "Run failed!"
        exit 3
    fi
fi
