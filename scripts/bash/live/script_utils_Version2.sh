#!/usr/bin/env bash
# script_utils.sh - common logging, error handling, and cleanup for all scripts
set -euo pipefail

# Load environment variables from .env file
load_env() {
  local env_file="${1:-.env}"
  if [[ -f "$env_file" ]]; then
    log "Loading environment from $env_file"
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
  else
    log "Warning: $env_file not found, environment variables must be set manually"
  fi
}

# Check if required API keys are set
check_api_key() {
  local key_name="$1"
  if [[ -z "${!key_name}" ]]; then
    log "Error: $key_name is not set. Add it to your .env file or environment"
    return 1
  fi
  return 0
}

# Logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$$] $*" >&2
}

# Cleanup function to kill child processes
cleanup() {
  log "Cleaning up child processes"
  pkill -P $$ || true
}

# Trap on errors
trap 'log "Error occurred at line $LINENO"; cleanup; exit 1' ERR

# Trap on termination signals
trap 'log "Received termination signal"; cleanup; exit 0' SIGTERM SIGINT

# Ensure cleanup on script exit
trap 'cleanup' EXIT