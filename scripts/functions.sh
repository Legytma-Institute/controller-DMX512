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
# v1.1.0 - Environment loading: functions.d/default_environments.sh is now
#           sourced unconditionally before filtered scripts, regardless of
#           whitelist/blacklist. Optional environments.sh (same dir) is sourced
#           after defaults; its values override matching defaults. Missing
#           default_environments.sh causes fail-fast (non-zero exit). Repeated
#           sourcing is idempotent via _FN_ENV_LOADED guard.
# v1.0.0 - Initial release. No prior loading behavior exists.
#           If future versions change whitelist/blacklist semantics or sourcing
#           order, document the change here and bump the version.

# --- Self-location (works when sourced or executed) ---
_FUNCTIONS_SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Logging helpers ---
_fn_log_prefix="[functions.sh]"

_fn_info()  {
  if command -v info &> /dev/null && [[ "$(command -v info)" == "info" ]]; then
    info "${_fn_log_prefix} $*"
  else
    echo "${_fn_log_prefix} $*"
  fi
}
_fn_warn()  {
  if command -v warn &> /dev/null && [[ "$(command -v warn)" == "warn" ]]; then
    warn "${_fn_log_prefix} WARN: $*"
  else
    echo "${_fn_log_prefix} WARN: $*" >&2
  fi
}
_fn_error() {
  if command -v error &> /dev/null && [[ "$(command -v error)" == "error" ]]; then
    error "${_fn_log_prefix} ERROR: $*"
  else
    echo "${_fn_log_prefix} ERROR: $*" >&2
  fi
}

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
  _FN_DISABLE_UPDATE="${FUNCTIONS_DISABLE_UPDATE:-0}"
  _FN_EFFECTIVE_WHITELIST=""
  _FN_EFFECTIVE_BLACKLIST=""
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
  if [[ "${_FN_DISABLE_UPDATE}" == "1" ]]; then
    return 1
  fi
  local last_check
  last_check="$(_fn_read_marker_ts)"
  local now
  now="$(date +%s)"
  local elapsed=$(( now - last_check ))
  if [[ $elapsed -lt 0 ]]; then
    elapsed=0
  fi
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

  # Preserve local/ across updates — never overwrite or remove user overrides
  local local_backup=""
  if [[ -d "$_FN_FUNCTIONS_DIR/local" ]]; then
    local_backup="$(mktemp -d)" || { _fn_error "Failed to create local backup dir"; _fn_cleanup_tmp; return 1; }
    cp -a "$_FN_FUNCTIONS_DIR/local" "$local_backup/local"
  fi

  # T022: Atomic replace
  if _fn_atomic_replace_dir "$tmp_dir/repo/functions.d" "$_FN_FUNCTIONS_DIR"; then
    # Restore local/ after replace
    if [[ -n "$local_backup" && -d "$local_backup/local" ]]; then
      rm -rf "$_FN_FUNCTIONS_DIR/local"
      mv "$local_backup/local" "$_FN_FUNCTIONS_DIR/local"
      rm -rf "$local_backup"
    else
      # Ensure local/ exists even if it didn't before
      mkdir -p "$_FN_FUNCTIONS_DIR/local"
      [[ -n "$local_backup" ]] && rm -rf "$local_backup"
    fi

    # Update this.sh (entrypoint) if present upstream
    local _fn_self_dir="$_FUNCTIONS_SELF_DIR"
    local this_sh_src="$tmp_dir/repo/this.sh"
    if [[ -f "$this_sh_src" ]]; then
      if cp "$this_sh_src" "${_fn_self_dir}/this.sh"; then
        chmod +x "${_fn_self_dir}/this.sh" 2>/dev/null || _fn_warn "Failed to chmod this.sh"
      else
        _fn_cleanup_tmp
        _fn_error "Failed to update this.sh"
        return 1
      fi
    fi

    # Update functions.sh (self) if present upstream
    local functions_sh_src="$tmp_dir/repo/functions.sh"
    if [[ -f "$functions_sh_src" ]]; then
      if cp "$functions_sh_src" "${_fn_self_dir}/functions.sh"; then
        chmod +x "${_fn_self_dir}/functions.sh" 2>/dev/null || _fn_warn "Failed to chmod functions.sh"
      else
        _fn_cleanup_tmp
        _fn_error "Failed to update functions.sh"
        return 1
      fi
    fi

    # Merge this.d scripts (preserve custom ones)
    if [[ -d "$tmp_dir/repo/this.d" ]]; then
      mkdir -p "${_fn_self_dir}/this.d"

      local upstream_script base_name custom_count=0 local_script
      for upstream_script in "$tmp_dir/repo/this.d"/*.sh; do
        [[ -f "$upstream_script" ]] || continue
        base_name="$(basename "$upstream_script")"
        if cp "$upstream_script" "${_fn_self_dir}/this.d/${base_name}"; then
          chmod +x "${_fn_self_dir}/this.d/${base_name}" 2>/dev/null || _fn_warn "Failed to chmod this.d/${base_name}"
        else
          _fn_cleanup_tmp
          _fn_error "Failed to install this.d/${base_name}"
          return 1
        fi
      done

      for local_script in "${_fn_self_dir}/this.d"/*.sh; do
        [[ -f "$local_script" ]] || continue
        base_name="$(basename "$local_script")"
        if [[ ! -f "$tmp_dir/repo/this.d/$base_name" ]]; then
          custom_count=$((custom_count + 1))
        fi
      done

      if [[ $custom_count -gt 0 ]]; then
        _fn_info "Preserved ${custom_count} custom script(s) in this.d/."
      fi
    fi

    _fn_cleanup_tmp
    _fn_write_marker "$remote_ref"
    local count
    count="$(find "$_FN_FUNCTIONS_DIR" -type f -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')"
    # T023: Clear messaging
    _fn_info "Updated functions.d to ${remote_ref:0:8} (${count} scripts)."
    return 0
  else
    [[ -n "$local_backup" ]] && rm -rf "$local_backup"
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
# Environment loading (bypasses whitelist/blacklist)  [FR-001..FR-006]
# ---------------------------------------------------------------------------
_fn_load_environment() {
  # FR-006: Idempotence guard — skip if already loaded in this session
  if [[ "${_FN_ENV_LOADED:-}" == "1" ]]; then
    return 0
  fi

  local _fn_prof_env_start
  if [[ "${FUNCTIONS_PROFILE_LOAD:-0}" == "1" ]]; then
    _fn_prof_env_start=$(date +%s%3N)
  fi

  local default_env="${_FN_FUNCTIONS_DIR}/default_environments.sh"

  # FR-001 / FR-005: default_environments.sh is mandatory — fail fast
  if [[ ! -f "$default_env" ]]; then
    _fn_error "Required file missing: ${default_env}"
    return 1
  fi
  if [[ ! -r "$default_env" ]]; then
    _fn_error "Required file not readable: ${default_env}"
    return 1
  fi

  # shellcheck source=/dev/null
  if ! source "$default_env"; then
    _fn_error "Failed to source: ${default_env}"
    return 1
  fi

  # FR-002 / FR-003: Source optional environments.sh (overrides defaults)
  local env_override="${_FUNCTIONS_SELF_DIR}/environments.sh"

  if [[ -f "$env_override" ]]; then
    if [[ -r "$env_override" ]]; then
      # shellcheck source=/dev/null
      if ! source "$env_override"; then
        _fn_warn "Failed to source: ${env_override} — continuing with defaults."
      fi
    else
      # FR-005: warn and continue when override file is unreadable
      _fn_warn "Override file not readable: ${env_override} — continuing with defaults."
    fi
  fi
  # FR-004: absence of environments.sh is silently accepted (no error)

  _FN_ENV_LOADED="1"

  if [[ "${FUNCTIONS_PROFILE_LOAD:-0}" == "1" && -n "${_fn_prof_env_start:-}" ]]; then
    local _fn_prof_env_end _fn_prof_env_ms
    _fn_prof_env_end=$(date +%s%3N)
    _fn_prof_env_ms=$(( _fn_prof_env_end - _fn_prof_env_start ))
    _fn_info "Profile: environment load ${_fn_prof_env_ms} ms"
  fi
}

# ---------------------------------------------------------------------------
# Load order
# ---------------------------------------------------------------------------
# Category load sequence:
#   1. default_environments.sh is sourced unconditionally (via _fn_load_environment).
#   2. All non-local categories under functions.d/ are sourced in sorted order,
#      respecting whitelist/blacklist filters.
#   3. functions.d/local/ (and its subcategories) is sourced LAST, using
#      filesystem discovery order. Functions defined in local/ override any
#      same-named functions loaded in step 2.
# ---------------------------------------------------------------------------

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

  local whitelist="${_FN_EFFECTIVE_WHITELIST:-${FUNCTIONS_WHITELIST:-}}"
  local blacklist="${_FN_EFFECTIVE_BLACKLIST:-${FUNCTIONS_BLACKLIST:-}}"

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

_this_get_require() {
  local script="$1"
  grep -m1 '^# @require ' "$script" 2>/dev/null | sed 's/^# @require //' || echo ""
}

_fn_source_functions() {
  if [[ ! -d "$_FN_FUNCTIONS_DIR" ]]; then
    _fn_warn "functions.d/ not found at ${_FN_FUNCTIONS_DIR}. Nothing to source."
    return 0
  fi

  local whitelist="${FUNCTIONS_WHITELIST:-}"
  local blacklist="${FUNCTIONS_BLACKLIST:-}"

  # If no explicit whitelist/blacklist, use .functions-required as whitelist fallback
  local required_file="${_FUNCTIONS_SELF_DIR}/.functions-required"
  if [[ -z "$whitelist" && -z "$blacklist" && -f "$required_file" ]]; then
    whitelist="$(set +e; grep -v '^[[:space:]]*$' "$required_file" | grep -v '^[[:space:]]*#' | tr '\n' ',' | sed 's/,$//'; set -e)"

    local -a _fn_whitelist_entries=()
    if [[ -n "$whitelist" ]]; then
      while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue
        _fn_whitelist_entries+=("$entry")
      done < <(echo "$whitelist" | tr ',' '\n')
    fi

    local scripts
    # Ensure logging helpers are always available when using required-file whitelist
    local scripts_requirements=("debug" "info" "warn" "error" "print_prompt" "${_fn_whitelist_entries[@]}")
    scripts="$(find "${_FUNCTIONS_SELF_DIR}/this.d" -maxdepth 1 -type f -name '*.sh' 2>/dev/null | sort)"

    if [[ ! -z "$scripts" ]]; then
      local script
      while IFS= read -r script; do
        [[ "$(basename "$script" .sh)" == _* ]] && continue
        local requires
        requires="$(_this_get_require "$script")"
        if [[ -n "$requires" ]]; then
          readarray -t requires <<< "${requires// /$'\n'}"
          scripts_requirements+=("${requires[@]}")
        fi
      done <<< "$scripts"
    fi

    local _fn_needed _fn_entry _found _continue
    while true; do
      _continue=0
      for _fn_needed in "${scripts_requirements[@]}"; do
        local script=$(find "$_FN_FUNCTIONS_DIR" -type f -name "$_fn_needed.sh" 2>/dev/null)

        if [ -f "$script" ]; then
          local require require_name
          while IFS= read -r require; do
            # remove optional surrounding quotes to avoid basename seeing them as part of filename
            local _require_path
            _require_path=${require%\"}
            _require_path=${_require_path#\"}
            require_name=$(basename -- "$_require_path" .sh)
            _found=0
            for _fn_entry in "${scripts_requirements[@]}"; do
              if [[ "$_fn_entry" == "$require_name" ]]; then
                _found=1
                break
              fi
            done
            if [[ $_found -eq 0 ]]; then
              scripts_requirements+=("$require_name")
              _continue=1
            fi
          done < <(set +e; grep '^source ' "$script" | sed 's/^source //' ; set -e)
        fi
      done

      if [ $_continue -eq 0 ]; then
        break
      fi
    done

    for _fn_needed in "${scripts_requirements[@]}"; do
      _found=0
      for _fn_entry in "${_fn_whitelist_entries[@]}"; do
        if [[ "$_fn_entry" == "$_fn_needed" ]]; then
          _found=1
          break
        fi
      done
      if [[ $_found -eq 0 ]]; then
        _fn_whitelist_entries+=("$_fn_needed")
      fi
    done

    whitelist="$(printf "%s," "${_fn_whitelist_entries[@]}")"
    whitelist="${whitelist%,}"
  fi

  _FN_EFFECTIVE_WHITELIST="$whitelist"
  _FN_EFFECTIVE_BLACKLIST="$blacklist"

  if [[ -n "$whitelist" && -n "$blacklist" ]]; then
    _fn_warn "Both FUNCTIONS_WHITELIST and FUNCTIONS_BLACKLIST are set. Blacklist will be ignored."
  fi

  local loaded=0 skipped=0 warned=0 local_overrides=0
  local file
  local local_dir="${_FN_FUNCTIONS_DIR}/local"

  # During bootstrap, skip inline dependency sourcing inside functions.d scripts.
  local _fn_bootstrap_source_guard_set=0
  if [[ -z "${FUNCTIONS_REGISTER_INLINE_SOURCES:-}" ]]; then
    _fn_bootstrap_source_guard_set=1
    source() {
      if [[ "${FUNCTIONS_REGISTER_INLINE_SOURCES:-0}" == "1" ]]; then
        return 0
      fi
      FUNCTIONS_REGISTER_INLINE_SOURCES=1
      builtin source "$@"
      FUNCTIONS_REGISTER_INLINE_SOURCES=0
    }
  fi

  # Collect function names defined before local/ for override detection
  local -A _fn_loaded_names=()

  # --- Pass 1: source all NON-local categories (sorted) ---
  while IFS= read -r file; do
    if [[ "$(basename "$file")" == "default_environments.sh" ]]; then
      continue
    fi
    if _fn_should_source_file "$file"; then
      local _fn_prof_start _fn_prof_ms
      if [[ "${FUNCTIONS_PROFILE_LOAD:-0}" == "1" ]]; then
        _fn_prof_start=$(date +%s%3N)
      fi
      # shellcheck source=/dev/null
      if source "$file" 2>/dev/null; then
        loaded=$((loaded + 1))
        _fn_loaded_names["$(basename "$file" .sh)"]=1
        if [[ "${FUNCTIONS_PROFILE_LOAD:-0}" == "1" && -n "${_fn_prof_start:-}" ]]; then
          local _fn_prof_end
          _fn_prof_end=$(date +%s%3N)
          _fn_prof_ms=$(( _fn_prof_end - _fn_prof_start ))
          _fn_info "Profile: $(basename "$file") ${_fn_prof_ms} ms"
        fi
      else
        _fn_warn "Failed to source: ${file}"
        warned=$((warned + 1))
      fi
    else
      skipped=$((skipped + 1))
    fi
  done < <(find "$_FN_FUNCTIONS_DIR" -type f -name '*.sh' -not -path "${local_dir}/*" 2>/dev/null | sort)

  # --- Pass 2: source local/ category LAST (filesystem discovery order) ---
  if [[ -d "$local_dir" ]]; then
    while IFS= read -r file; do
      if _fn_should_source_file "$file"; then
        local _fn_prof_start _fn_prof_ms
        if [[ "${FUNCTIONS_PROFILE_LOAD:-0}" == "1" ]]; then
          _fn_prof_start=$(date +%s%3N)
        fi
        local base_name
        base_name="$(basename "$file" .sh)"
        # shellcheck source=/dev/null
        if source "$file" 2>/dev/null; then
          loaded=$((loaded + 1))
          if [[ -n "${_fn_loaded_names[$base_name]+_}" ]]; then
            _fn_info "Local override: ${base_name} (from ${file})"
            local_overrides=$((local_overrides + 1))
          fi
          if [[ "${FUNCTIONS_PROFILE_LOAD:-0}" == "1" && -n "${_fn_prof_start:-}" ]]; then
            local _fn_prof_end
            _fn_prof_end=$(date +%s%3N)
            _fn_prof_ms=$(( _fn_prof_end - _fn_prof_start ))
            _fn_info "Profile: $(basename "$file") ${_fn_prof_ms} ms"
          fi
        else
          _fn_warn "Failed to source: ${file}"
          warned=$((warned + 1))
        fi
      else
        skipped=$((skipped + 1))
      fi
    done < <(find "$local_dir" -type f -name '*.sh' 2>/dev/null)
  fi

  # Restore normal source behavior
  if [[ $_fn_bootstrap_source_guard_set -eq 1 ]]; then
    unset -f source
    unset FUNCTIONS_REGISTER_INLINE_SOURCES
  fi

  if [[ $warned -gt 0 || $local_overrides -gt 0 ]]; then
    _fn_info "Loaded ${loaded} function(s), skipped ${skipped}, warnings ${warned}, local overrides ${local_overrides}."
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

Load order:
  1. functions.d/default_environments.sh  Sourced unconditionally first
  2. environments.sh                     Sourced unconditionally first (if exists)
  2. Non-local categories                Sorted order, respecting whitelist/blacklist
  3. functions.d/local/                  Loaded LAST (filesystem discovery order)
                                         Functions here override same-named core functions.
                                         This directory is preserved across updates.
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
  _fn_load_environment || { _fn_error "Environment loading failed. Aborting."; return 1; }
  _fn_source_functions
fi
