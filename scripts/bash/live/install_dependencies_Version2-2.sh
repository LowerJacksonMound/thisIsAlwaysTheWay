#!/usr/bin/env bash
# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/script_utils.sh"

usage() {
  log "Usage: $(basename "$0") [-e ENV_FILE] [-v VENV_PATH]"
  log "  -e ENV_FILE  : Path to .env file (default: .env in script directory)"
  log "  -v VENV_PATH : Path to create virtual environment (optional)"
  exit 1
}

ENV_FILE="${SCRIPT_DIR}/.env"
VENV_PATH=""

# Parse options
while getopts ":e:v:" opt; do
  case "${opt}" in
    e) ENV_FILE="${OPTARG}" ;;
    v) VENV_PATH="${OPTARG}" ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

main() {
  # Load environment variables
  load_env "$ENV_FILE"
  
  # Check if pip is installed
  if ! command -v pip &> /dev/null; then
    log "Error: pip is not installed. Please install Python and pip first."
    exit 1
  fi
  
  # Create and activate virtual environment if specified
  if [[ -n "${VENV_PATH}" ]]; then
    log "Creating virtual environment at ${VENV_PATH}"
    if ! command -v python3 &> /dev/null; then
      log "Error: python3 is not installed. Cannot create virtual environment."
      exit 1
    fi
    
    python3 -m venv "${VENV_PATH}" || {
      log "Error: Failed to create virtual environment"
      exit 1
    }
    
    # Source the activate script
    # shellcheck disable=SC1090
    source "${VENV_PATH}/bin/activate" || {
      log "Error: Failed to activate virtual environment"
      exit 1
    }
    
    log "Activated virtual environment at ${VENV_PATH}"
  fi

  log "Installing Python dependencies..."
  pip install --upgrade \
    requests \
    tweepy \
    schedule \
    pytest \
    black \
    pytest-bash \
    python-dotenv \
    youtube-dl || {
      log "Error: Failed to install dependencies"
      exit 1
    }
  
  log "Dependencies installation completed successfully"
}

main "$@"