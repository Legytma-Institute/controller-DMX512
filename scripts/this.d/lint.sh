#!/usr/bin/env bash
# @description Run Python lint/format/typecheck (black/flake8/mypy)
# @require ensure_dev_dependencies debug info

set -euo pipefail

LINT_ARGUMENTS=("$@")

debug "Running lint..."

ensure_dev_dependencies

if [ ${#LINT_ARGUMENTS[@]} -gt 0 ]; then
    "${VENV_PY}" -m black "${LINT_ARGUMENTS[@]}"
    "${VENV_PY}" -m flake8 "${LINT_ARGUMENTS[@]}"
    "${VENV_PY}" -m mypy "${LINT_ARGUMENTS[@]}"
else
    "${VENV_PY}" -m black src
    "${VENV_PY}" -m flake8 src
    "${VENV_PY}" -m mypy src
fi

info "Lint completed successfully"
