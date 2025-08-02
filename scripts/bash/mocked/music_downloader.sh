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

  local KEYWORDS=""
  local SELECTION=""

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
      *)
        usage
        ;;
    esac
  done

  if [[ -z "$KEYWORDS" || -z "$SELECTION" ]]; then
    log "Error: --keywords and --selection are required."
    usage
  fi

  mkdir -p "${OUTPUT_DIR}"
  log "Downloading music: keywords='${KEYWORDS}', selection='${SELECTION}', output='${OUTPUT_DIR}'"

  youtube-dl "https://www.youtube.com/results?search_query=${KEYWORDS// /+}"     -o "${OUTPUT_DIR}/%(title)s.%(ext)s" || {
      log "Error: Music download failed"
      exit 1
    }

  log "Music download completed"
}

main "$@"
