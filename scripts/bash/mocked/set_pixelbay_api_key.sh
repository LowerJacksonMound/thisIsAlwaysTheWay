#!/usr/bin/env bash
source "$(dirname "$0")/script_utils.sh"

usage() {
  log "Usage: $(basename "$0")"
  log "Ensure PIXABAY_API_KEY is set in the environment"
  exit 1
}

main() {
  if [[ -z "${PIXABAY_API_KEY:-}" ]]; then
    log "PIXABAY_API_KEY not provided"
    usage
  fi

  export PIXABAY_API_KEY
  log "PIXABAY_API_KEY is set"
}

main "$@"
