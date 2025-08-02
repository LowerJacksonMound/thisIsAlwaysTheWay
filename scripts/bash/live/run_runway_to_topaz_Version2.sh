#!/usr/bin/env bash
source "$(dirname "$0")/script_utils.sh"

usage() {
  log "Usage: $(basename "$0") [input_dir] [output_dir]"
  log "  Executes the runway_to_topaz.sh script with the specified directories"
  log "  If no directories are provided, defaults will be used"
  exit 1
}

main() {
  local SCRIPT
  SCRIPT="$(dirname "$0")/runway_to_topaz.sh"
  
  local INPUT_DIR="${1:-${HOME}/Videos/Input}"
  local OUTPUT_DIR="${2:-${HOME}/Videos/Output}"

  if [[ ! -x "${SCRIPT}" ]]; then
    log "ERROR: ${SCRIPT} not found or not executable"
    log "INFO: Attempting to make script executable..."
    
    if [[ -f "${SCRIPT}" ]]; then
      chmod +x "${SCRIPT}" || {
        log "ERROR: Failed to make script executable"
        exit 1
      }
      log "SUCCESS: Made script executable"
    else
      log "ERROR: Script file does not exist"
      exit 1
    fi
  fi

  log "INFO: Executing ${SCRIPT} with input='${INPUT_DIR}' output='${OUTPUT_DIR}'"
  
  # Create directories if they don't exist
  mkdir -p "${INPUT_DIR}" || {
    log "ERROR: Failed to create input directory: ${INPUT_DIR}"
    exit 1
  }
  
  mkdir -p "${OUTPUT_DIR}" || {
    log "ERROR: Failed to create output directory: ${OUTPUT_DIR}"
    exit 1
  }
  
  # Execute the script with proper arguments
  "${SCRIPT}" "${INPUT_DIR}" "${OUTPUT_DIR}" || {
    log "ERROR: Script execution failed with exit code $?"
    exit 1
  }
  
  log "SUCCESS: Execution of ${SCRIPT} completed"
}

main "$@"