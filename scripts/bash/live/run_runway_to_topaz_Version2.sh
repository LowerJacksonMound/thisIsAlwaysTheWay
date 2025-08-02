#!/usr/bin/env bash
# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/script_utils.sh"

usage() {
  log "Usage: $(basename "$0") [-e ENV_FILE] [-i INPUT_FILE] [-o OUTPUT_DIR]"
  log "  -e ENV_FILE   : Path to .env file (default: .env in script directory)"
  log "  -i INPUT_FILE : Input file to process (optional)"
  log "  -o OUTPUT_DIR : Output directory (optional)"
  exit 1
}

ENV_FILE="${SCRIPT_DIR}/.env"
INPUT_FILE=""
OUTPUT_DIR=""

# Parse options
while getopts ":e:i:o:" opt; do
  case "${opt}" in
    e) ENV_FILE="${OPTARG}" ;;
    i) INPUT_FILE="${OPTARG}" ;;
    o) OUTPUT_DIR="${OPTARG}" ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

main() {
  # Load environment variables
  load_env "$ENV_FILE"
  
  # Check required API keys
  check_api_key "RUNWAY_API_KEY" || exit 1
  check_api_key "TOPAZ_API_KEY" || exit 1
  
  local SCRIPT="${SCRIPT_DIR}/runway_to_topaz.sh"

  if [[ ! -x "${SCRIPT}" ]]; then
    log "Error: ${SCRIPT} not found or not executable"
    log "Try running make_runway_to_topaz_executable.sh first"
    exit 1
  fi

  log "Executing ${SCRIPT}"
  
  # Build command with optional arguments
  local cmd=("${SCRIPT}")
  
  if [[ -n "${INPUT_FILE}" ]]; then
    if [[ ! -f "${INPUT_FILE}" ]]; then
      log "Error: Input file ${INPUT_FILE} does not exist"
      exit 1
    fi
    cmd+=("-i" "${INPUT_FILE}")
  fi
  
  if [[ -n "${OUTPUT_DIR}" ]]; then
    mkdir -p "${OUTPUT_DIR}"
    cmd+=("-o" "${OUTPUT_DIR}")
  fi
  
  # Execute with environment variables exported
  export RUNWAY_API_KEY
  export TOPAZ_API_KEY
  
  "${cmd[@]}"
  
  local exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    log "Error: ${SCRIPT} failed with exit code ${exit_code}"
    exit ${exit_code}
  fi
  
  log "Execution of ${SCRIPT} completed successfully"
}

main "$@"