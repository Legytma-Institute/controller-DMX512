#!/usr/bin/env bash
# @description Request update of bash-lib

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_force=false

while [[ $# -gt 0 ]]; do
    case "$1" in
    --force)
        _force=true
        shift 1
        ;;
    --help)
        echo "Request update of bash-lib"
        echo ""
        echo "Usage: $0 [--force]"
        echo ""
        echo "Options:"
        echo "  --force    Force update ignoring actual version"
        exit 0
        ;;
    *)
        echo "Usage: $0 [--force]"
        exit 1
        ;;
    esac
done

if [ "$_force" = true ]; then
    rm -rf "${SELF_DIR}"/../.functions-update-marker
fi

"${SELF_DIR}"/../functions.sh --update-now
