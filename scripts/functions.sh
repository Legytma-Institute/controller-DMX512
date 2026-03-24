#!/usr/bin/env bash
#
# functions.sh - Bash library loader and updater.
#
# When sourced: checks for updates (respecting interval), then sources functions
#               from functions.d/ according to whitelist/blacklist rules.
# When executed: supports --update-now, --help flags.
#
# Environment variables:
#   FUNCTIONS_REPO_URL          Remote git repository URL
#   FUNCTIONS_SOURCE_REF        Branch/ref to track (default: HEAD)
#   FUNCTIONS_UPDATE_INTERVAL   Seconds between update checks (default: 86400 = 1 day)
#   FUNCTIONS_WHITELIST         Comma-separated allowlist (overrides blacklist)
#   FUNCTIONS_BLACKLIST         Comma-separated denylist
#

# --- Migration notes ---
# v1.0.0 - Initial release. No prior loading behavior exists.
#           If future versions change whitelist/blacklist semantics or sourcing
#           order, document the change here and bump the version.

# --- Self-location (works when sourced or executed) ---
_FUNCTIONS_SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Logging helpers ---
_fn_log_prefix="[functions.sh]"

_fn_info()  { echo "${_fn_log_prefix} $*"; }
_fn_warn()  { echo "${_fn_log_prefix} WARN: $*" >&2; }
_fn_error() { echo "${_fn_log_prefix} ERROR: $*" >&2; }

# --- Configuration loader ---
_fn_load_config() {
  local config_file="${_FUNCTIONS_SELF_DIR}/.functions-config"
  if [[ -f "$config_file" ]]; then
    # shellcheck source=/dev/null
    source "$config_file"
  fi

  _FN_REPO_URL="${FUNCTIONS_REPO_URL:-git@github.com:Legytma/bash-lib.git}"
  _FN_SOURCE_REF="${FUNCTIONS_SOURCE_REF:-HEAD}"
  _FN_UPDATE_INTERVAL="${FUNCTIONS_UPDATE_INTERVAL:-86400}"
  _FN_MARKER_FILE="${_FUNCTIONS_SELF_DIR}/.functions-update-marker"
  _FN_FUNCTIONS_DIR="${_FUNCTIONS_SELF_DIR}/functions.d"
}

# ---------------------------------------------------------------------------
# Update marker helpers (T005)
# Marker format: line 1 = epoch timestamp, line 2 = commit hash (optional)
# ---------------------------------------------------------------------------
_fn_read_marker_ts() {
  if [[ -f "$_FN_MARKER_FILE" ]]; then
    head -n1 "$_FN_MARKER_FILE" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

_fn_read_marker_ref() {
  if [[ -f "$_FN_MARKER_FILE" ]]; then
    sed -n '2p' "$_FN_MARKER_FILE" 2>/dev/null || echo ""
  else
    echo ""
  fi
}

_fn_write_marker() {
  local ref="${1:-}"
  {
    date +%s
    echo "$ref"
  } > "$_FN_MARKER_FILE"
}

_fn_should_update() {
  local last_check
  last_check="$(_fn_read_marker_ts)"
  local now
  now="$(date +%s)"
  local elapsed=$(( now - last_check ))
  [[ $elapsed -ge $_FN_UPDATE_INTERVAL ]]
}

# ---------------------------------------------------------------------------
# Atomic directory replace helper (T004)
# ---------------------------------------------------------------------------
_fn_atomic_replace_dir() {
  local src="$1"
  local dest="$2"

  if [[ ! -d "$src" ]]; then
    _fn_error "Source directory does not exist: $src"
    return 1
  fi

  local backup="${dest}.old.$$"

  if [[ -d "$dest" ]]; then
    mv "$dest" "$backup"
  fi

  if mv "$src" "$dest"; then
    rm -rf "$backup"
    return 0
  else
    # Restore backup on failure
    if [[ -d "$backup" ]]; then
      mv "$backup" "$dest"
    fi
    _fn_error "Failed to replace directory: $dest"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Prerequisite check
# ---------------------------------------------------------------------------
_fn_check_prerequisites() {
  local missing=()
  for cmd in git tar; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    _fn_error "Missing required tools: ${missing[*]}"
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Update logic (T020-T024)
# ---------------------------------------------------------------------------
_fn_do_update() {
  if [[ -z "$_FN_REPO_URL" ]]; then
    _fn_warn "No repository URL configured. Skipping update."
    return 0
  fi

  if ! _fn_check_prerequisites; then
    return 1
  fi

  # T020: Default-branch tracking with env override via _FN_SOURCE_REF
  _fn_info "Checking for updates (ref: ${_FN_SOURCE_REF}) ..."

  # Lightweight remote check: compare commit hashes before downloading
  local remote_ref
  remote_ref="$(git ls-remote "$_FN_REPO_URL" "$_FN_SOURCE_REF" 2>/dev/null | awk '{print $1}' | head -n1)" || true

  if [[ -z "$remote_ref" ]]; then
    _fn_error "Failed to query remote ref '${_FN_SOURCE_REF}' from ${_FN_REPO_URL}"
    return 1
  fi

  local stored_ref
  stored_ref="$(_fn_read_marker_ref)"

  if [[ "$remote_ref" == "$stored_ref" ]]; then
    _fn_info "Already up-to-date (${remote_ref:0:8})."
    _fn_write_marker "$remote_ref"
    return 0
  fi

  # Ref differs — shallow clone to get latest functions.d
  local tmp_dir
  tmp_dir="$(mktemp -d)" || { _fn_error "Failed to create temp directory"; return 1; }

  # T024: Cleanup temp on any exit path
  _fn_cleanup_tmp() { rm -rf "$tmp_dir"; }

  local clone_args=(clone --depth=1)
  if [[ "$_FN_SOURCE_REF" != "HEAD" && -n "$_FN_SOURCE_REF" ]]; then
    clone_args+=(--branch "$_FN_SOURCE_REF")
  fi
  clone_args+=("$_FN_REPO_URL" "$tmp_dir/repo")

  if ! git "${clone_args[@]}" 2>/dev/null; then
    _fn_cleanup_tmp
    _fn_error "Failed to clone ${_FN_REPO_URL} (ref: ${_FN_SOURCE_REF})"
    return 1
  fi

  if [[ ! -d "$tmp_dir/repo/functions.d" ]]; then
    _fn_cleanup_tmp
    _fn_error "Cloned repository does not contain functions.d/"
    return 1
  fi

  # T022: Atomic replace
  if _fn_atomic_replace_dir "$tmp_dir/repo/functions.d" "$_FN_FUNCTIONS_DIR"; then
    _fn_cleanup_tmp
    _fn_write_marker "$remote_ref"
    local count
    count="$(find "$_FN_FUNCTIONS_DIR" -type f -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')"
    # T023: Clear messaging
    _fn_info "Updated functions.d to ${remote_ref:0:8} (${count} scripts)."
    return 0
  else
    _fn_cleanup_tmp
    # T024: Leave prior functions.d intact on failure
    _fn_error "Atomic replace failed. Previous functions.d left intact."
    return 1
  fi
}

# T021: Interval-gated wrapper; --update-now bypasses the gate
_fn_maybe_update() {
  if _fn_should_update; then
    _fn_do_update || _fn_warn "Update check failed; continuing with existing functions."
  fi
}

# ---------------------------------------------------------------------------
# Whitelist / Blacklist filtering (T030-T032)
# ---------------------------------------------------------------------------
# Parse a comma-or-space-separated list into newline-separated entries.
_fn_parse_list() {
  local input="$1"
  echo "$input" | tr ',' '\n' | tr ' ' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$'
}

# Decide whether a single .sh file should be sourced based on filters.
_fn_should_source_file() {
  local file_path="$1"
  local rel_path="${file_path#"${_FN_FUNCTIONS_DIR}"/}"

  # Decompose path: category[/subcategory]/script.sh
  local category subcategory script_name
  category="$(echo "$rel_path" | cut -d'/' -f1)"
  script_name="$(basename "$rel_path" .sh)"

  local depth
  depth="$(echo "$rel_path" | awk -F'/' '{print NF}')"
  if [[ $depth -ge 3 ]]; then
    subcategory="$(echo "$rel_path" | cut -d'/' -f2)"
  else
    subcategory=""
  fi

  local whitelist="${FUNCTIONS_WHITELIST:-}"
  local blacklist="${FUNCTIONS_BLACKLIST:-}"

  if [[ -n "$whitelist" ]]; then
    local entry
    while IFS= read -r entry; do
      [[ -z "$entry" ]] && continue
      if [[ "$category" == "$entry" ]] || \
         [[ -n "$subcategory" && "$subcategory" == "$entry" ]] || \
         [[ "$script_name" == "$entry" ]] || \
         [[ -n "$subcategory" && "$category/$subcategory" == "$entry" ]]; then
        return 0
      fi
    done < <(_fn_parse_list "$whitelist")
    return 1
  elif [[ -n "$blacklist" ]]; then
    local entry
    while IFS= read -r entry; do
      [[ -z "$entry" ]] && continue
      if [[ "$category" == "$entry" ]] || \
         [[ -n "$subcategory" && "$subcategory" == "$entry" ]] || \
         [[ "$script_name" == "$entry" ]] || \
         [[ -n "$subcategory" && "$category/$subcategory" == "$entry" ]]; then
        return 1
      fi
    done < <(_fn_parse_list "$blacklist")
    return 0
  fi

  # No filter — load all
  return 0
}

_fn_source_functions() {
  if [[ ! -d "$_FN_FUNCTIONS_DIR" ]]; then
    _fn_warn "functions.d/ not found at ${_FN_FUNCTIONS_DIR}. Nothing to source."
    return 0
  fi

  local whitelist="${FUNCTIONS_WHITELIST:-}"
  local blacklist="${FUNCTIONS_BLACKLIST:-}"

  if [[ -n "$whitelist" && -n "$blacklist" ]]; then
    _fn_warn "Both FUNCTIONS_WHITELIST and FUNCTIONS_BLACKLIST are set. Blacklist will be ignored."
  fi

  local loaded=0 skipped=0 warned=0
  local file

  while IFS= read -r file; do
    if _fn_should_source_file "$file"; then
      # shellcheck source=/dev/null
      if source "$file" 2>/dev/null; then
        loaded=$((loaded + 1))
      else
        _fn_warn "Failed to source: ${file}"
        warned=$((warned + 1))
      fi
    else
      skipped=$((skipped + 1))
    fi
  done < <(find "$_FN_FUNCTIONS_DIR" -type f -name '*.sh' 2>/dev/null | sort)

  if [[ $warned -gt 0 ]]; then
    _fn_info "Loaded ${loaded} function(s), skipped ${skipped}, warnings ${warned}."
  else
    _fn_info "Loaded ${loaded} function(s), skipped ${skipped}."
  fi
}

# ---------------------------------------------------------------------------
# CLI interface (when executed, not sourced)
# ---------------------------------------------------------------------------
_fn_usage() {
  cat <<'EOF'
functions.sh - Bash library loader and updater.

Usage (sourced — auto-update + load):
  source scripts/functions.sh

Usage (executed):
  scripts/functions.sh [OPTIONS]

Options:
  --update-now     Force an update check, bypassing the interval
  --help           Show this help message

Environment:
  FUNCTIONS_REPO_URL          Remote git repository URL
  FUNCTIONS_SOURCE_REF        Branch/ref to track (default: HEAD)
  FUNCTIONS_UPDATE_INTERVAL   Seconds between update checks (default: 86400)
  FUNCTIONS_WHITELIST         Comma-separated allowlist (overrides blacklist)
  FUNCTIONS_BLACKLIST         Comma-separated denylist
EOF
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
_fn_load_config

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Executed directly — strict mode is safe here
  set -euo pipefail

  _action=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --update-now) _action="update"; shift ;;
      --help)       _fn_usage; exit 0 ;;
      *)            _fn_error "Unknown option: $1. Use --help for usage."; exit 1 ;;
    esac
  done

  case "$_action" in
    update) _fn_do_update ;;
    "")     _fn_usage; exit 0 ;;
  esac
else
  # Sourced — no strict mode to avoid killing caller's shell
  _fn_maybe_update
  _fn_source_functions
fi
