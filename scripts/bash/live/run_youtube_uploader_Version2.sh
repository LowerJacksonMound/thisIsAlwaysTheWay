#!/usr/bin/env bash
source "$(dirname "$0")/script_utils.sh"

usage() {
  log "Usage: $(basename "$0") -d VIDEO_DIR -k KEYWORDS -s SELECTION"
  log "  -d VIDEO_DIR   Directory to store downloaded videos (default: $HOME/Videos/ToUpload)"
  log "  -k KEYWORDS    Search keywords for YouTube videos"
  log "  -s SELECTION   Selection criteria (first, popular, or number)"
  exit 1
}

VIDEO_DIR="$HOME/Videos/ToUpload"
KEYWORDS=""
SELECTION=""

# Parse options
while getopts ":d:k:s:h" opt; do
  case "${opt}" in
    d) VIDEO_DIR="${OPTARG}" ;;
    k) KEYWORDS="${OPTARG}" ;;
    s) SELECTION="${OPTARG}" ;;
    h) usage ;;
    *) log "ERROR: Invalid option: -${OPTARG}"; usage ;;
  esac
done
shift $((OPTIND - 1))

main() {
  if [[ -z "${KEYWORDS}" || -z "${SELECTION}" ]]; then
    log "ERROR: Keywords (-k) and selection criteria (-s) are required"
    usage
  fi

  mkdir -p "${VIDEO_DIR}" || {
    log "ERROR: Failed to create video directory: ${VIDEO_DIR}"
    exit 1
  }
  
  log "INFO: Starting YouTube downloader with:"
  log "INFO: - Video directory: ${VIDEO_DIR}"
  log "INFO: - Keywords: ${KEYWORDS}"
  log "INFO: - Selection: ${SELECTION}"
  
  # Check if OAuth credentials exist
  if [[ ! -f "${HOME}/.google_oauth_credentials.json" ]]; then
    log "ERROR: Google OAuth 2.0 credentials not found. Please run setup_google_oauth.sh first."
    exit 1
  }
  
  # Call the music_downloader.sh script with proper arguments
  local DOWNLOADER_SCRIPT
  DOWNLOADER_SCRIPT="$(dirname "$0")/music_downloader.sh"
  
  if [[ ! -x "${DOWNLOADER_SCRIPT}" ]]; then
    log "ERROR: ${DOWNLOADER_SCRIPT} not found or not executable"
    if [[ -f "${DOWNLOADER_SCRIPT}" ]]; then
      log "INFO: Attempting to make script executable..."
      chmod +x "${DOWNLOADER_SCRIPT}" || {
        log "ERROR: Failed to make script executable"
        exit 1
      }
    else
      log "ERROR: Script file does not exist"
      exit 1
    fi
  }
  
  log "INFO: Executing ${DOWNLOADER_SCRIPT}"
  "${DOWNLOADER_SCRIPT}" "${VIDEO_DIR}" --keywords "${KEYWORDS}" --selection "${SELECTION}" || {
    log "ERROR: Download failed with exit code $?"
    exit 1
  }
  
  log "SUCCESS: YouTube download completed"
}

main "$@"