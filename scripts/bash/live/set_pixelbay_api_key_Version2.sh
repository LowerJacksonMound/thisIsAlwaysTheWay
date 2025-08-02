#!/usr/bin/env bash
source "$(dirname "$0")/script_utils.sh"

usage() {
  log "Usage: $(basename "$0")"
  log "  Sets the Pixabay API key for use with other scripts"
  log "  Ensure PIXABAY_API_KEY is set in the environment"
  log "  Example: PIXABAY_API_KEY=your-key-here $(basename "$0")"
  exit 1
}

main() {
  if [[ -z "${PIXABAY_API_KEY:-}" ]]; then
    log "ERROR: PIXABAY_API_KEY not provided"
    usage
  fi

  # Save to configuration file for persistence
  config_dir="${HOME}/.config/script_utils"
  mkdir -p "${config_dir}" || {
    log "ERROR: Failed to create config directory: ${config_dir}"
    exit 1
  }
  
  echo "${PIXABAY_API_KEY}" > "${config_dir}/pixabay_api_key.txt" || {
    log "ERROR: Failed to write API key to file"
    exit 1
  }
  
  chmod 600 "${config_dir}/pixabay_api_key.txt" || {
    log "WARNING: Failed to set secure permissions on API key file"
  }
  
  export PIXABAY_API_KEY
  log "SUCCESS: PIXABAY_API_KEY is set and saved to ${config_dir}/pixabay_api_key.txt"
}

main "$@"