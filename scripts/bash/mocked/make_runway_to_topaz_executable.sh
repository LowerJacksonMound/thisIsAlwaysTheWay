#!/usr/bin/env bash
source "$(dirname "$0")/script_utils.sh"

main() {
  local SCRIPT
  SCRIPT="$(dirname "$0")/runway_to_topaz.sh"

  if [[ ! -f "${SCRIPT}" ]]; then
    log "Error: runway_to_topaz.sh not found at ${SCRIPT}"
    exit 1
  fi

  chmod +x "${SCRIPT}"
  log "Made ${SCRIPT} executable"
}

main "$@"
