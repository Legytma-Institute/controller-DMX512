#!/usr/bin/env bash
# @description Run Python tests (pytest)
# @require ensure_dev_dependencies debug info error

set -euo pipefail

TEST_ARGUMENTS=("$@")

debug "Running test..."

ensure_dev_dependencies

if "${VENV_PY}" -m pytest "${TEST_ARGUMENTS[@]}"; then
    info "Test succeeded!"
else
    error "Test failed!"
    exit 1
fi
