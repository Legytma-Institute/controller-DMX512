#!/usr/bin/env bash

ensure_venv() {
    if [ ! -d "${VENV_DIR}" ]; then
        "${PYTHON_BIN}" -m venv "${VENV_DIR}"
    fi

    "${VENV_PY}" -m pip install -U pip setuptools wheel
}

export -f ensure_venv
