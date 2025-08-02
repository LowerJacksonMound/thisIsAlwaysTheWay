#!/usr/bin/env bash
# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/script_utils.sh"

usage() {
  log "Usage: $(basename "$0") -d VIDEO_DIR -k KEYWORDS -s SELECTION [-e ENV_FILE]"
  log "  -d VIDEO_DIR   : Directory for video files (default: $HOME/Videos/ToUpload)"
  log "  -k KEYWORDS    : Keywords for search"
  log "  -s SELECTION   : Selection criteria"
  log "  -e ENV_FILE    : Path to .env file (default: .env in script directory)"
  exit 1
}

VIDEO_DIR="$HOME/Videos/ToUpload"
KEYWORDS=""
SELECTION=""
ENV_FILE="${SCRIPT_DIR}/.env"

# Parse options
while getopts ":d:k:s:e:" opt; do
  case "${opt}" in
    d) VIDEO_DIR="${OPTARG}" ;;
    k) KEYWORDS="${OPTARG}" ;;
    s) SELECTION="${OPTARG}" ;;
    e) ENV_FILE="${OPTARG}" ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

main() {
  if [[ -z "${KEYWORDS}" || -z "${SELECTION}" ]]; then
    usage
  fi

  # Load environment variables
  load_env "$ENV_FILE"
  
  # Check required API keys
  check_api_key "YOUTUBE_API_KEY" || exit 1
  check_api_key "DOWNLOAD_API_KEY" || exit 1
  
  # Create directory if it doesn't exist
  mkdir -p "${VIDEO_DIR}"
  
  # Check if music_downloader.py exists
  local downloader="${SCRIPT_DIR}/music_downloader.py"
  if [[ ! -f "$downloader" ]]; then
    log "Error: music_downloader.py not found at ${downloader}"
    exit 1
  fi
  
  log "Downloading music to '${VIDEO_DIR}' with keywords '${KEYWORDS}' (selection: '${SELECTION}')..."
  
  # Run the Python script with proper environment variables
  YOUTUBE_API_KEY="${YOUTUBE_API_KEY}" \
  DOWNLOAD_API_KEY="${DOWNLOAD_API_KEY}" \
  python "${downloader}" "${VIDEO_DIR}" \
    --keywords "${KEYWORDS}" \
    --selection "${SELECTION}"
    
  if [[ $? -ne 0 ]]; then
    log "Error: Download failed"
    exit 1
  fi
  
  log "Download completed successfully"
}

main "$@"