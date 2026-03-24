#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ensure_venv.sh"

ensure_dev_dependencies() {
    ensure_venv

    if [ -f "${CURRENT_DIR}/pyproject.toml" ]; then
        "${VENV_PY}" -m pip install -e ".[dev]"
    elif [ -f "${CURRENT_DIR}/requirements.txt" ]; then
        "${VENV_PY}" -m pip install -r "${CURRENT_DIR}/requirements.txt"
    fi
}

export -f ensure_dev_dependencies
