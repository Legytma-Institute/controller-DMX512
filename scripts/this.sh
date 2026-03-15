#!/usr/bin/env bash

set -e

if [ -t 0 ] && [ -t 1 ]; then
    clear
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./functions.sh
source "${SCRIPT_DIR}"/functions.sh

#
# Load .env file
#
load_env_file

PYTHON_BIN="${PYTHON_BIN:-python3}"
VENV_DIR="${VENV_DIR:-${CURRENT_DIR}/.venv}"
VENV_PY="${VENV_DIR}/bin/python"

ensure_venv() {
    if [ ! -d "${VENV_DIR}" ]; then
        "${PYTHON_BIN}" -m venv "${VENV_DIR}"
    fi

    "${VENV_PY}" -m pip install -U pip setuptools wheel
}

ensure_dev_dependencies() {
    ensure_venv

    if [ -f "${CURRENT_DIR}/pyproject.toml" ]; then
        "${VENV_PY}" -m pip install -e ".[dev]"
    elif [ -f "${CURRENT_DIR}/requirements.txt" ]; then
        "${VENV_PY}" -m pip install -r "${CURRENT_DIR}/requirements.txt"
    fi
}

# Parse arguments
SPECIFY_ARGUMENTS=()
TEST_ARGUMENTS=()
LINT_ARGUMENTS=()
BUILD_ARGUMENTS=()
RUN_ARGUMENTS=()
UNSPECIFIED_ARGUMENTS=()
ARGUMENT_CONTEXT="unspecified"
HELP=false
SPECIFY=false
TEST=false
LINT=false
BUILD=false
RUN=false

if [ $# -eq 0 ]; then
    HELP=true
fi

# Function to handle argument based on context
handle_argument() {
    local ARGUMENT

    ARGUMENT="$1"

    case "${ARGUMENT_CONTEXT}" in
        specify)
            SPECIFY_ARGUMENTS+=("${ARGUMENT}")
            ;;
        test)
            TEST_ARGUMENTS+=("${ARGUMENT}")
            ;;
        lint)
            LINT_ARGUMENTS+=("${ARGUMENT}")
            ;;
        build)
            BUILD_ARGUMENTS+=("${ARGUMENT}")
            ;;
        run)
            RUN_ARGUMENTS+=("${ARGUMENT}")
            ;;
        *)
            HELP=true
            UNSPECIFIED_ARGUMENTS+=("${ARGUMENT}")
            ;;
    esac
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --)
            shift 1
            while [[ $# -gt 0 ]]; do
                handle_argument "$1"
                shift 1
            done
            ;;
        --help)
            HELP=true
            shift 1
            ;;
        --specify)
            SPECIFY=true
            ARGUMENT_CONTEXT="specify"
            shift 1
            ;;
        --build)
            BUILD=true
            ARGUMENT_CONTEXT="build"
            shift 1
            ;;
        --lint)
            LINT=true
            ARGUMENT_CONTEXT="lint"
            shift 1
            ;;
        --test)
            TEST=true
            ARGUMENT_CONTEXT="test"
            shift 1
            ;;
        --run)
            RUN=true
            ARGUMENT_CONTEXT="run"
            shift 1
            ;;
        *)
            handle_argument "$1"
            shift 1
            ;;
    esac
done

if [ "${HELP}" == "true" ]; then
    if [ ${#UNSPECIFIED_ARGUMENTS[@]} -gt 0 ]; then
        echo -e "\033[31mInvalid arguments at this context: \033[33m${UNSPECIFIED_ARGUMENTS[*]}\033[0m" >&2
        echo "" >&2
    fi

    echo -e "Usage: \033[32mthis \033[33m[options]\033[0m"
    echo ""
    echo "Options:"
    echo -e "  \033[33m--help \033[34m\033[0m                 Show this help message"
    echo -e "  \033[33m--specify \033[34m[arguments]\033[0m   Initialize a new spec-kit repository passing arguments to the specify command"
    echo -e "  \033[33m--lint \033[34m[arguments]\033[0m      Run Python lint/format/typecheck (black/flake8/mypy)"
    echo -e "  \033[33m--test \033[34m[arguments]\033[0m      Run Python tests (pytest)"
    echo -e "  \033[33m--build \033[34m[arguments]\033[0m     Build the Python package (python -m build)"
    echo -e "  \033[33m--run \033[34m[arguments]\033[0m       Run the application (dmx-controller)"
    echo ""

    if [ ${#UNSPECIFIED_ARGUMENTS[@]} -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
fi

if [ "${SPECIFY}" == "true" ]; then
    echo -e "\033[33mRunning specify...\033[0m" >&2

    if run_specify "${SPECIFY_ARGUMENTS[@]}"; then
        echo -e "\033[32mSpecify succeeded\033[0m" >&2
    else
        echo -e "\033[31mSpecify failed\033[0m" >&2
        exit 2
    fi
fi

if [ "${LINT}" == "true" ]; then
    echo -e "\033[33mRunning lint...\033[0m" >&2

    ensure_dev_dependencies

    if [ ${#LINT_ARGUMENTS[@]} -gt 0 ]; then
        "${VENV_PY}" -m black "${LINT_ARGUMENTS[@]}"
        "${VENV_PY}" -m flake8 "${LINT_ARGUMENTS[@]}"
        "${VENV_PY}" -m mypy "${LINT_ARGUMENTS[@]}"
    else
        "${VENV_PY}" -m black .
        "${VENV_PY}" -m flake8 .
        "${VENV_PY}" -m mypy src
    fi

    if [ $? -eq 0 ]; then
        echo -e "\033[32mLint succeeded!\033[0m" >&2
    else
        echo -e "\033[31mLint failed!\033[0m" >&2
        exit 4
    fi
fi

if [ "${BUILD}" == "true" ]; then
    echo -e "\033[33mRunning build...\033[0m" >&2

    ensure_dev_dependencies

    if ! "${VENV_PY}" -c "import build" > /dev/null 2>&1; then
        "${VENV_PY}" -m pip install -U build
    fi

    if "${VENV_PY}" -m build "${BUILD_ARGUMENTS[@]}"; then
        echo -e "\033[32mBuild succeeded\033[0m" >&2
    else
        echo -e "\033[31mBuild failed\033[0m" >&2
        exit 3
    fi
fi

if [ "${TEST}" == "true" ]; then
    echo -e "\033[33mRunning test...\033[0m" >&2

    ensure_dev_dependencies

    if "${VENV_PY}" -m pytest "${TEST_ARGUMENTS[@]}"; then
        echo -e "\033[32mTest succeeded!\033[0m" >&2
    else
        echo -e "\033[31mTest failed!\033[0m" >&2
        exit 5
    fi
fi

if [ "${RUN}" == "true" ]; then
    echo -e "\033[33mRunning app...\033[0m" >&2

    ensure_dev_dependencies

    if [ -x "${VENV_DIR}/bin/dmx-controller" ]; then
        if "${VENV_DIR}/bin/dmx-controller" "${RUN_ARGUMENTS[@]}"; then
            echo -e "\033[32mRun succeeded!\033[0m" >&2
        else
            echo -e "\033[31mRun failed!\033[0m" >&2
            exit 6
        fi
    else
        if "${VENV_PY}" -m controller_dmx512.main "${RUN_ARGUMENTS[@]}"; then
            echo -e "\033[32mRun succeeded!\033[0m" >&2
        else
            echo -e "\033[31mRun failed!\033[0m" >&2
            exit 6
        fi
    fi
fi
