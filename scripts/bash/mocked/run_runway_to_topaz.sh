#!/usr/bin/env bash
source "$(dirname "$0")/script_utils.sh"

main() {
  local SCRIPT
  SCRIPT="$(dirname "$0")/runway_to_topaz.sh"

  if [[ ! -x "${SCRIPT}" ]]; then
    log "Error: ${SCRIPT} not found or not executable"
    exit 1
  fi

  log "Executing ${SCRIPT}"
  bash "${SCRIPT}"
  log "Execution of ${SCRIPT} completed"
}

main "$@"
