#!/usr/bin/env bash
source "$(dirname "$0")/script_utils.sh"

main() {
  local SCRIPT
  SCRIPT="$(dirname "$0")/runway_to_topaz.sh"

  if [[ ! -f "${SCRIPT}" ]]; then
    log "ERROR: runway_to_topaz.sh not found at ${SCRIPT}"
    exit 1
  fi

  log "INFO: Checking current permissions on ${SCRIPT}"
  local current_perms
  current_perms=$(stat -c "%A" "${SCRIPT}" 2>/dev/null || stat -f "%Lp" "${SCRIPT}" 2>/dev/null)
  
  if [[ -z "${current_perms}" ]]; then
    log "WARNING: Could not determine current permissions"
  else
    log "INFO: Current permissions: ${current_perms}"
  fi

  log "INFO: Setting executable permissions on ${SCRIPT}"
  chmod +x "${SCRIPT}" || {
    log "ERROR: Failed to set executable permissions on ${SCRIPT}"
    exit 1
  }
  
  if [[ ! -x "${SCRIPT}" ]]; then
    log "ERROR: Failed to verify executable permissions on ${SCRIPT}"
    exit 1
  }
  
  log "SUCCESS: Made ${SCRIPT} executable"
}

main "$@"