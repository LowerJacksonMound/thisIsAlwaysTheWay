#!/usr/bin/env bash
source "$(dirname "$0")/script_utils.sh"

usage() {
  log "Usage: $(basename "$0") <input_dir> <output_dir>"
  log "  Process video files from input_dir through Runway ML and Topaz Video AI"
  exit 1
}

main() {
  if [[ $# -lt 2 ]]; then
    log "ERROR: Missing required arguments"
    usage
  fi

  local INPUT_DIR="$1"
  local OUTPUT_DIR="$2"

  # Validate directories
  if [[ ! -d "${INPUT_DIR}" ]]; then
    log "ERROR: Input directory '${INPUT_DIR}' does not exist"
    exit 1
  fi

  mkdir -p "${OUTPUT_DIR}" || {
    log "ERROR: Failed to create output directory '${OUTPUT_DIR}'"
    exit 1
  }

  log "INFO: Starting Runway → Topaz integration"
  log "INFO: Input directory: ${INPUT_DIR}"
  log "INFO: Output directory: ${OUTPUT_DIR}"

  # Ensure Runway CLI is available
  if ! command -v runway >/dev/null 2>&1; then
    log "ERROR: 'runway' CLI not found. Please install RunwayML CLI."
    exit 1
  fi

  # Process each file in the input directory
  found_files=false
  for infile in "${INPUT_DIR}"/*.{mp4,mov,mkv}; do
    # Skip if no files match pattern
    [[ -e "$infile" ]] || continue
    found_files=true
    
    outfile="${OUTPUT_DIR}/$(basename "${infile%.*}")_topaz.${infile##*.}"
    log "INFO: Processing: $infile → ${outfile}"

    # Run Runway ML headless
    log "INFO: Generating with Runway ML..."
    runway ml generate "$infile" --output "${outfile}.tmp" 2>&1 | while read -r line; do
      log "RUNWAY: ${line}"
    done
    
    if [[ ! -f "${outfile}.tmp" ]]; then
      log "ERROR: Runway ML generation failed for $infile"
      continue
    fi

    # Ensure Topaz CLI is available
    if ! command -v topaz >/dev/null 2>&1; then
      log "ERROR: 'topaz' CLI not found. Please install Topaz Video AI CLI."
      rm -f "${outfile}.tmp"
      exit 1
    fi

    # Topaz Video AI enhancement
    log "INFO: Enhancing with Topaz Video AI..."
    topaz video-enhance --input "${outfile}.tmp" --output "${outfile}" --preset standard 2>&1 | while read -r line; do
      log "TOPAZ: ${line}"
    done
    
    if [[ ! -f "${outfile}" ]]; then
      log "ERROR: Topaz Video AI enhancement failed for ${outfile}.tmp"
      rm -f "${outfile}.tmp"
      continue
    fi

    rm -f "${outfile}.tmp"
    log "SUCCESS: Processed: ${outfile}"
  done

  if [[ "$found_files" == false ]]; then
    log "WARNING: No video files found in ${INPUT_DIR}"
  fi

  log "INFO: Runway → Topaz integration completed"
}

main "$@"