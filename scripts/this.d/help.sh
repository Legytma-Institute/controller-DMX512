#!/usr/bin/env bash
# @description Show available commands and usage

set -euo pipefail

cat <<'EOF'
this.sh is a command runner for bash-lib

Usage: scripts/this.sh <command> [args...]
       scripts/this.sh --command1 [--command2 ...] [-- args...]

Run 'scripts/this.sh -h' for the full command listing.

functions.sh is a bash library loader and updater.

Usage (sourced — auto-update + load):
  source scripts/functions.sh

Usage (executed):
  scripts/functions.sh [OPTIONS]

Run 'scripts/functions.sh --help' for the functions help usage.
EOF
