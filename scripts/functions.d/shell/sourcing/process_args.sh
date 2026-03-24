#!/usr/bin/env bash

#
# Process arguments
#
function process_args() {
    # If no arguments are provided, set --init else process arguments
    if [ $# -eq 0 ]; then
        INIT=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --)
                    shift
                    while [[ $# -gt 0 ]]; do
                        handle_argument "$1"
                        shift
                    done
                    ;;
                --clean)
                    CLEAN=true
                    shift
                    ;;
                --help)
                    HELP=0
                    shift
                    ;;
                --init)
                    INIT=true
                    shift
                    ;;
                --start)
                    START=true
                    shift
                    ;;
                --show)
                    SHOW=true
                    shift
                    ;;
                --firefly)
                    FIREFLY=true
                    FABLO=false
                    ARGUMENT_CONTEXT="firefly"
                    shift
                    ;;
                --fablo)
                    FABLO=true
                    FIREFLY=false
                    ARGUMENT_CONTEXT="fablo"
                    shift
                    ;;
                --enforce-functions-link)
                    ENFORCE_FUNCTIONS_LINK=true
                    shift
                    ;;
                --force-rebuild)
                    FORCE_REBUILD=true
                    shift
                    ;;
                *)
                    handle_argument "$1"
                    shift
                    ;;
            esac
        done
    fi
}

export -f process_args
