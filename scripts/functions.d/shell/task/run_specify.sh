#!/usr/bin/env bash

#
# Run specify
#
function run_specify() {
    local ARGUMENTS

    ARGUMENTS=()

    if [ $# -eq 0 ]; then
        ARGUMENTS+=("init" "--here" "--script" "sh" "--ai" "windsurf" "--force")
    else
        ARGUMENTS+=("$@")
    fi

    uvx --refresh --upgrade --no-cache --from "git+https://github.com/github/spec-kit" specify "${ARGUMENTS[@]}"
}

export -f run_specify
