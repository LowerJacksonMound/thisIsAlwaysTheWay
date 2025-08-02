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
