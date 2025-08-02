#!/usr/bin/env bash
# script_utils.sh - common logging, error handling, and cleanup for all scripts
set -euo pipefail

# Logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$$] $*"
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
