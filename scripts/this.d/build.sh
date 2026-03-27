#!/usr/bin/env bash
# @description Build the Python package (python -m build)
# @require ensure_dev_dependencies debug info error

set -euo pipefail

BUILD_ARGUMENTS=("$@")

debug "Running build..."

ensure_dev_dependencies

if ! "${VENV_PY}" -c "import build" > /dev/null 2>&1; then
    "${VENV_PY}" -m pip install -U build
fi

if "${VENV_PY}" -m build "${BUILD_ARGUMENTS[@]}"; then
    info "Build succeeded"
else
    error "Build failed"
    exit 1
fi
