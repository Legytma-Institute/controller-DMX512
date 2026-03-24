#!/usr/bin/env bash

#
# Show help
#
function show_help() {
    if [ ${#UNSPECIFIED_ARGUMENTS[@]} -gt 0 ]; then
        echo -e "\033[31mInvalid arguments at this context: \033[33m${UNSPECIFIED_ARGUMENTS[*]}\033[0m" >&2
        echo "" >&2
    fi

    echo "Usage: $0 [options] [arguments]"
    echo ""
    echo "Options:"
    echo "  --clean                     Clean the environment"
    echo "  --force-rebuild             Force rebuild of containers"
    echo "  --init                      Initialize the environment"
    echo "  --start                     Start the environment"
    echo "  --firefly                   Pass arguments to firefly"
    echo "  --fablo                     Pass arguments to fablo"
    echo "  --enforce-functions-link    Enforce functions link"
    echo "  --help                      Show this help"
    echo ""
    echo "Arguments:"
    echo "  All arguments are passed directly to the engine"
    echo ""
    echo "Examples:"
    echo "  $0 --clean --firefly init test"
    echo "  $0 --clean --fablo up"
    echo "  $0 --clean --fablo up --firefly init test"
    echo "  $0 --help"
    echo ""

    if [ ${#UNSPECIFIED_ARGUMENTS[@]} -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

export -f show_help
