#!/usr/bin/env bash
# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/script_utils.sh"

usage() {
  log "Usage: $(basename "$0") <output_dir> [OPTIONS]"
  log "Options:"
  log "  --keywords <keywords>    : Search keywords (required)"
  log "  --selection <selection>  : Selection criteria (required)"
  log "  --env-file <env_file>    : Path to .env file (default: .env in script directory)"
  log "  --limit <count>          : Maximum number of videos to download (default: 5)"
  exit 1
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
  fi

  local OUTPUT_DIR="$1"
  shift

  local KEYWORDS=""
  local SELECTION=""
  local ENV_FILE="${SCRIPT_DIR}/.env"
  local LIMIT=5

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --keywords)
        KEYWORDS="$2"
        shift 2
        ;;
      --selection)
        SELECTION="$2"
        shift 2
        ;;
      --env-file)
        ENV_FILE="$2"
        shift 2
        ;;
      --limit)
        LIMIT="$2"
        shift 2
        ;;
      *)
        usage
        ;;
    esac
  done

  if [[ -z "$KEYWORDS" || -z "$SELECTION" ]]; then
    log "Error: --keywords and --selection are required."
    usage
  fi

  # Load environment variables
  load_env "$ENV_FILE"
  
  # Check for required API key
  check_api_key "YOUTUBE_API_KEY" || exit 1
  
  # Check if youtube-dl is installed
  if ! command -v youtube-dl &> /dev/null; then
    log "Error: youtube-dl is not installed. Run install_dependencies.sh first."
    exit 1
  fi

  mkdir -p "${OUTPUT_DIR}" || {
    log "Error: Failed to create output directory ${OUTPUT_DIR}"
    exit 1
  }
  
  log "Downloading music: keywords='${KEYWORDS}', selection='${SELECTION}', output='${OUTPUT_DIR}', limit=${LIMIT}"
  
  # Construct search URL with API key
  local SEARCH_URL="https://www.googleapis.com/youtube/v3/search?part=snippet&q=${KEYWORDS// /+}&type=video&key=${YOUTUBE_API_KEY}&maxResults=${LIMIT}"
  
  # Get video IDs
  local VIDEO_IDS
  VIDEO_IDS=$(curl -s "$SEARCH_URL" | jq -r '.items[] | select(.snippet.title | contains("'"${SELECTION}"'")) | .id.videoId')
  
  if [[ -z "$VIDEO_IDS" ]]; then
    log "Error: No videos found matching criteria"
    exit 1
  fi
  
  # Download each video
  for video_id in $VIDEO_IDS; do
    log "Downloading video ID: ${video_id}"
    youtube-dl "https://www.youtube.com/watch?v=${video_id}" \
      -o "${OUTPUT_DIR}/%(title)s.%(ext)s" \
      --extract-audio \
      --audio-format mp3 \
      --audio-quality 0 || {
        log "Warning: Failed to download video ID ${video_id}, continuing..."
      }
  done

  log "Music download completed successfully"
}

main "$@"