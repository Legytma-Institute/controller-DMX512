#!/usr/bin/env bash
#
# this.sh - Script entrypoint dispatcher.
#
# Dispatches to sub-command scripts in this.d/ with lifecycle hooks.
# Supports three invocation modes:
#   - Single-dash first arg (-h, -help): this.sh's own flags
#   - Positional (bare word):            single sub-command dispatch
#   - Dashed-flag (--name):              multi sub-command dispatch
#
# Lifecycle order:
#   1. Source functions.sh        (mandatory)
#   2. Source hooks/pre-execute.sh (optional)
#   3. Dispatch sub-command(s)
#   4. Source hooks/post-execute.sh (optional)
#

set -euo pipefail

# --- Self-location (works when sourced or executed) ---
_THIS_SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Logging helpers ---
_this_log_prefix="[this.sh]"

# shellcheck disable=SC2317
_this_info()  { info "${_this_log_prefix} $*"; }
_this_warn()  { warn "${_this_log_prefix} WARN: $*"; }
_this_error() { error "${_this_log_prefix} ERROR: $*"; }

if [ -t 0 ] && [ -t 1 ]; then
    clear
    echo ""
fi

# ---------------------------------------------------------------------------
# FR-001: Source functions.sh (mandatory — fail fast if missing)
# ---------------------------------------------------------------------------
_THIS_FUNCTIONS_SH="${_THIS_SELF_DIR}/functions.sh"
# # Prefer offline update skip for CLI responsiveness; allow caller override
# : "${FUNCTIONS_DISABLE_UPDATE:=1}"
if [[ ! -f "$_THIS_FUNCTIONS_SH" ]]; then
  _this_error "Required file missing: ${_THIS_FUNCTIONS_SH}"
  exit 1
fi
# shellcheck source=/dev/null
source "$_THIS_FUNCTIONS_SH"

if [ -t 0 ] && [ -t 1 ]; then
  if command -v print_prompt &> /dev/null && [[ "$(command -v print_prompt)" == "print_prompt" ]]; then
    if [ "$0" == "${_THIS_SELF_DIR}/this.sh" ] && [ "$(command -v $(basename "$0" .sh))" == "$(basename "$0" .sh)" ]; then
      # Get the current command name without the extension
      _CURRENT_COMMAND=$(basename "$0" .sh)
    else
      _CURRENT_COMMAND="$0"
    fi

    tput sc
    tput cup 0 0

    print_prompt "${_CURRENT_COMMAND} $*"

    tput rc
  fi
fi

# ---------------------------------------------------------------------------
# FR-014: Hook sourcing helper — warn-and-skip on failure
# ---------------------------------------------------------------------------
_this_source_hook() {
  local hook_path="$1"
  if [[ ! -f "$hook_path" ]]; then
    return 0
  fi
  if [[ ! -r "$hook_path" ]]; then
    _this_warn "Hook not readable, skipping: ${hook_path}"
    return 0
  fi
  # shellcheck source=/dev/null
  if ! source "$hook_path"; then
    _this_warn "Hook failed to source, skipping: ${hook_path}"
    return 0
  fi
}

_THIS_HOOKS_DIR="${_THIS_SELF_DIR}/hooks"
_THIS_COMMANDS_DIR="${_THIS_SELF_DIR}/this.d"

# ---------------------------------------------------------------------------
# FR-003: Source hooks/pre-execute.sh before dispatch
# ---------------------------------------------------------------------------
_this_source_hook "${_THIS_HOOKS_DIR}/pre-execute.sh"

# ---------------------------------------------------------------------------
# FR-018: Single-dash first arg = this.sh's own flags (only when $1)
# FR-005/FR-012: _this_show_help defined later; called by -h/-help and no-args
# ---------------------------------------------------------------------------
_this_get_description() {
  local script="$1"
  grep -m1 '^# @description ' "$script" 2>/dev/null | sed 's/^# @description //' || echo ""
}

_this_show_help() {
  echo "This is a command runner for bash-lib"
  echo ""
  echo "Usage: this.sh <command> [args...]"
  echo "       this.sh --command1 [--command2 ...] [-- args...]"
  echo "       this.sh -h"
  echo ""

  if [[ ! -d "$_THIS_COMMANDS_DIR" ]]; then
    echo "No commands directory found."
    return 0
  fi

  local scripts
  scripts="$(find "$_THIS_COMMANDS_DIR" -maxdepth 1 -type f -name '*.sh' 2>/dev/null | sort)"

  if [[ -z "$scripts" ]]; then
    echo "No commands available."
    return 0
  fi

  echo "Available commands:"

  local max_len=0 name
  while IFS= read -r script; do
    name="$(basename "$script" .sh)"
    [[ "$name" == _* ]] && continue
    [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]] && continue
    if [[ ${#name} -gt $max_len ]]; then
      max_len=${#name}
    fi
  done <<< "$scripts"

  local desc
  while IFS= read -r script; do
    name="$(basename "$script" .sh)"
    [[ "$name" == _* ]] && continue
    [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]] && continue
    desc="$(_this_get_description "$script")"
    printf "  %-${max_len}s  %s\n" "$name" "$desc"
  done <<< "$scripts"
}

_this_exit_code=0

if [[ $# -eq 0 ]]; then
  # FR-005: No arguments — source on-no-arguments hook if present, else show help
  _this_on_no_args_hook="${_THIS_HOOKS_DIR}/on-no-arguments.sh"
  if [[ -f "$_this_on_no_args_hook" ]]; then
    _this_source_hook "$_this_on_no_args_hook"
  else
    _this_show_help
  fi
elif [[ "$1" == -* && "$1" != --* ]]; then
  # Single-dash first arg — this.sh's own flag
  case "$1" in
    -h|-help)
      _this_show_help
      exit 0
      ;;
    *)
      _this_error "Unknown flag: $1. Use -h for help."
      exit 1
      ;;
  esac
elif [[ "$1" != --* ]]; then
  # ---------------------------------------------------------------------------
  # Positional mode — single sub-command (FR-006)
  # ---------------------------------------------------------------------------
  _this_cmd_name="$1"
  shift

  if [[ ! -d "$_THIS_COMMANDS_DIR" ]]; then
    _this_error "Commands directory not found: ${_THIS_COMMANDS_DIR}"
    _this_exit_code=1
  elif [[ ! "$_this_cmd_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    _this_error "Invalid command name: ${_this_cmd_name}"
    _this_exit_code=1
  else
    _this_script="${_THIS_COMMANDS_DIR}/${_this_cmd_name}.sh"
    if [[ ! -f "$_this_script" ]]; then
      _this_error "Unknown command: ${_this_cmd_name} (${_this_script} not found)"
      _this_exit_code=1
    else
      bash "$_this_script" "$@" || _this_exit_code=$?
    fi
  fi
else
  # ---------------------------------------------------------------------------
  # Dashed-flag mode — multi sub-command (FR-007, FR-008, FR-016, FR-017, FR-018)
  # ---------------------------------------------------------------------------
  if [[ ! -d "$_THIS_COMMANDS_DIR" ]]; then
    _this_error "Commands directory not found: ${_THIS_COMMANDS_DIR}"
    _this_exit_code=1
  else
    # Accumulated commands: parallel arrays for scripts and their args
    _this_cmd_scripts=()
    _this_cmd_args=()
    _this_active_idx=-1

    while [[ $# -gt 0 ]]; do
      _this_arg="$1"
      shift

      if [[ "$_this_arg" == "--" ]]; then
        # FR-009: Double-dash passthrough — all remaining to last active
        if [[ $_this_active_idx -lt 0 ]]; then
          _this_error "No command before '--'. Nothing to receive arguments."
          _this_exit_code=1
          break
        fi
        # Append all remaining args to last active command
        while [[ $# -gt 0 ]]; do
          _this_cmd_args[_this_active_idx]+=" $(printf '%q' "$1")"
          shift
        done
        break
      elif [[ "$_this_arg" == --* ]]; then
        # Double-dash arg: check if it maps to a sub-command
        _this_flag_name="${_this_arg#--}"
        _this_candidate="${_THIS_COMMANDS_DIR}/${_this_flag_name}.sh"

        if [[ "$_this_flag_name" =~ ^[a-zA-Z0-9_-]+$ ]] && [[ -f "$_this_candidate" ]]; then
          # New active sub-command
          _this_active_idx=$(( ${#_this_cmd_scripts[@]} ))
          _this_cmd_scripts+=("$_this_candidate")
          _this_cmd_args+=("")
        elif [[ $_this_active_idx -lt 0 ]]; then
          # No active command yet — error
          _this_error "No matching command for '${_this_arg}' and no prior command to receive it."
          _this_exit_code=1
          break
        else
          # Unrecognised flag — append to active command's args
          _this_cmd_args[_this_active_idx]+=" $(printf '%q' "$_this_arg")"
        fi
      else
        # Single-dash or bare word after first arg — append to active command
        if [[ $_this_active_idx -lt 0 ]]; then
          _this_error "No matching command for '${_this_arg}' and no prior command to receive it."
          _this_exit_code=1
          break
        fi
        _this_cmd_args[_this_active_idx]+=" $(printf '%q' "$_this_arg")"
      fi
    done

    # Execute accumulated commands sequentially (FR-007, FR-016)
    if [[ $_this_exit_code -eq 0 ]]; then
      for _this_i in "${!_this_cmd_scripts[@]}"; do
        _this_run_script="${_this_cmd_scripts[$_this_i]}"
        _this_run_args="${_this_cmd_args[$_this_i]}"
        eval "bash \"$_this_run_script\" $_this_run_args" || {
          _this_exit_code=$?
          break
        }
      done
    fi
  fi
fi

# ---------------------------------------------------------------------------
# FR-004: Source hooks/post-execute.sh after dispatch (always runs)
# ---------------------------------------------------------------------------
_this_source_hook "${_THIS_HOOKS_DIR}/post-execute.sh"

exit "${_this_exit_code}"
