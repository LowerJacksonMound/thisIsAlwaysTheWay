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
