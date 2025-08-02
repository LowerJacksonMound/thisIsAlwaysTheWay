# script_utils.sh
#!/usr/bin/env bash
# script_utils.sh - common logging, error handling, and cleanup for all scripts
set -euo pipefail

# Logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$$] $*"
}

# Cleanup function to kill child processes
cleanup() {
  log "Cleaning up child processes"
  pkill -P $$ || true
}

# Trap on errors
trap 'log "Error occurred at line $LINENO"; cleanup; exit 1' ERR

# Trap on termination signals
trap 'log "Received termination signal"; cleanup; exit 0' SIGTERM SIGINT

# Ensure cleanup on script exit
trap 'cleanup' EXIT


# run_youtube_uploader.sh
#!/usr/bin/env bash
source "$(dirname "$0")/script_utils.sh"

usage() {
  log "Usage: $(basename "$0") -d VIDEO_DIR -k KEYWORDS -s SELECTION"
  exit 1
}

VIDEO_DIR="$HOME/Videos/ToUpload"
KEYWORDS=""
SELECTION=""

# Parse options
while getopts ":d:k:s:" opt; do
  case "${opt}" in
    d) VIDEO_DIR="${OPTARG}" ;;  
    k) KEYWORDS="${OPTARG}" ;;  
    s) SELECTION="${OPTARG}" ;;  
    *) usage ;;  
  esac
done
shift $((OPTIND - 1))

main() {
  if [[ -z "${VIDEO_DIR}" || -z "${KEYWORDS}" || -z "${SELECTION}" ]]; then
    usage
  fi

  mkdir -p "${VIDEO_DIR}"
  log "Downloading music to '${VIDEO_DIR}' with keywords '${KEYWORDS}' (selection: '${SELECTION}')..."
  python music_downloader.py "${VIDEO_DIR}" \
    --keywords "${KEYWORDS}" \
    --selection "${SELECTION}"
  log "Download completed"
}

main "$@"


# make_runway_to_topaz_executable.sh
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


# run_runway_to_topaz.sh
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


# runway_to_topaz.sh
#!/usr/bin/env bash
source "$(dirname "$0")/script_utils.sh"

main() {
  log "Starting Runway to Topaz integration"
  # TODO: insert actual runway integration commands here

  log "Launching Runway ML..."
  runway ml start

  log "Processing in Topaz Video AI..."
  osascript -e 'tell application "Topaz Video AI" to activate'
  # ... perform Topaz operations ...
  osascript -e 'tell application "Topaz Video AI" to quit'

  log "Runway to Topaz integration completed"
}

main "$@"


# install_dependencies.sh
#!/usr/bin/env bash
source "$(dirname "$0")/script_utils.sh"

main() {
  log "Installing Python dependencies"
  pip install --upgrade \
    requests \
    tweepy \
    schedule \
    pytest \
    black \
    pytest-bash
  log "Dependencies installation completed"
}

main "$@"


# set_runwaynll_api_secrect.sh
#!/usr/bin/env bash
source "$(dirname "$0")/script_utils.sh"

usage() {
  log "Usage: $(basename "$0")"
  log "Ensure RUNWAYNLL_API_SECRET is set in the environment"
  exit 1
}

main() {
  if [[ -z "${RUNWAYNLL_API_SECRET:-}" ]]; then
    log "RUNWAYNLL_API_SECRET not set"
    usage
  fi

  export RUNWAYNLL_API_SECRET
  log "RUNWAYNLL_API_SECRET is set"
}

main "$@"


# set_pixelbay_api_key.sh
#!/usr/bin/env bash
source "$(dirname "$0")/script_utils.sh"

usage() {
  log "Usage: $(basename "$0")"
  log "Ensure PIXABAY_API_KEY is set in the environment"
  exit 1
}

main() {
  if [[ -z "${PIXABAY_API_KEY:-}" ]]; then
    log "PIXABAY_API_KEY not provided"
    usage
  fi

  export PIXABAY_API_KEY
  log "PIXABAY_API_KEY is set"
}

main "$@"


# music_downloader.sh
#!/usr/bin/env bash
source "$(dirname "$0")/script_utils.sh"

usage() {
  log "Usage: $(basename "$0") <output_dir> --keywords <keywords> --selection <selection>"
  exit 1
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
  fi

  local OUTPUT_DIR="$1"
  shift

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --keywords)
        shift
        KEYWORDS="$1"
        ;;  
      --selection)
        shift
        SELECTION="$1"
        ;;  
      *)
        usage
        ;;  
    esac
    shift
  done

  if [[ -z "${OUTPUT_DIR}" || -z "${KEYWORDS:-}" || -z "${SELECTION:-}" ]]; then
    usage
  fi

  mkdir -p "${OUTPUT_DIR}"
  log "Starting music download for keywords '${KEYWORDS}' selection '${SELECTION}' into '${OUTPUT_DIR}'"

  # Example download command (replace with actual logic)
  youtube-dl "https://www.youtube.com/results?search_query=${KEYWORDS// /+}" \
    -o "${OUTPUT_DIR}/%(title)s.%(ext)s"

  log "Music download completed"
}

main "$@"
