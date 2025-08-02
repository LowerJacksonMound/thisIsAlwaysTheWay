#!/usr/bin/env bash
source "$(dirname "$0")/script_utils.sh"

usage() {
  log "Usage: $(basename "$0") <input_dir> <output_dir>"
  exit 1
}

main() {
  if [[ $# -lt 2 ]]; then
    usage
  fi

  local INPUT_DIR="$1"
  local OUTPUT_DIR="$2"

  mkdir -p "${OUTPUT_DIR}"

  log "Starting Runway → Topaz integration"

  # Ensure Runway CLI is available
  if ! command -v runway >/dev/null 2>&1; then
    log "Error: 'runway' CLI not found. Please install RunwayML CLI."
    exit 1
  fi

  # Process each file in the input directory
  for infile in "${INPUT_DIR}"/*.{mp4,mov,mkv}; do
    [[ -e "$infile" ]] || continue
    outfile="${OUTPUT_DIR}/$(basename "${infile%.*}")_topaz.${infile##*.}"
    log "Generating with Runway ML: $infile → ${outfile}"

    # Run Runway ML headless (example; adjust model/app as needed)
    runway ml generate "$infile" --output "${outfile}.tmp" || {
      log "Error: Runway ML generation failed for $infile"
      exit 1
    }

    # Ensure Topaz CLI is available
    if ! command -v topaz >/dev/null 2>&1; then
      log "Error: 'topaz' CLI not found. Please install Topaz Video AI CLI."
      exit 1
    fi

    # Topaz Video AI enhancement (example preset; adjust as needed)
    log "Enhancing with Topaz Video AI: ${outfile}.tmp → ${outfile}"
    topaz video-enhance --input "${outfile}.tmp" --output "${outfile}" --preset standard || {
      log "Error: Topaz Video AI enhancement failed for ${outfile}.tmp"
      rm -f "${outfile}.tmp"
      exit 1
    }

    rm -f "${outfile}.tmp"
    log "Processed: ${outfile}"
  done

  log "Runway → Topaz integration completed"
}

main "$@"
