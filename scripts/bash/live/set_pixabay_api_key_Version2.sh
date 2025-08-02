#!/usr/bin/env bash
# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/script_utils.sh"

usage() {
  log "Usage: $(basename "$0") [-e ENV_FILE] [-k API_KEY]"
  log "  -e ENV_FILE : Path to .env file (default: .env in script directory)"
  log "  -k API_KEY  : Pixabay API key (optional, can be read from .env file)"
  exit 1
}

ENV_FILE="${SCRIPT_DIR}/.env"
API_KEY=""

# Parse options
while getopts ":e:k:" opt; do
  case "${opt}" in
    e) ENV_FILE="${OPTARG}" ;;
    k) API_KEY="${OPTARG}" ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

main() {
  # Load environment variables
  load_env "$ENV_FILE"
  
  # If API key is provided as argument, use it; otherwise check environment
  if [[ -z "${API_KEY}" ]]; then
    API_KEY="${PIXABAY_API_KEY:-}"
  fi
  
  if [[ -z "${API_KEY}" ]]; then
    log "Error: Pixabay API key not provided"
    usage
  fi
  
  # Save API key to .env file
  if [[ ! -f "${ENV_FILE}" ]]; then
    touch "${ENV_FILE}" || {
      log "Error: Cannot create ${ENV_FILE}"
      exit 1
    }
  fi
  
  # Check if PIXABAY_API_KEY already exists in the file
  if grep -q "^PIXABAY_API_KEY=" "${ENV_FILE}"; then
    # Replace existing entry
    sed -i.bak "s/^PIXABAY_API_KEY=.*/PIXABAY_API_KEY=${API_KEY}/" "${ENV_FILE}" || {
      log "Error: Failed to update API key in ${ENV_FILE}"
      exit 1
    }
    rm -f "${ENV_FILE}.bak"
  else
    # Add new entry
    echo "PIXABAY_API_KEY=${API_KEY}" >> "${ENV_FILE}" || {
      log "Error: Failed to add API key to ${ENV_FILE}"
      exit 1
    }
  fi
  
  export PIXABAY_API_KEY="${API_KEY}"
  log "PIXABAY_API_KEY is set and saved to ${ENV_FILE}"
}

main "$@"