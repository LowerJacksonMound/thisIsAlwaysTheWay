#!/usr/bin/env bash
source "$(dirname "$0")/script_utils.sh"

usage() {
  log "Usage: $(basename "$0") <output_dir> --keywords <keywords> --selection <selection>"
  log "  Download music from YouTube using Google OAuth 2.0"
  log "  output_dir: Directory to save downloaded files"
  log "  keywords: Search terms for finding music"
  log "  selection: Specific selection criteria (e.g., 'first', 'popular')"
  exit 1
}

main() {
  if [[ $# -lt 1 ]]; then
    log "ERROR: Missing required arguments"
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
        log "ERROR: Unknown option: $1"
        usage
        ;;
    esac
  done

  if [[ -z "$KEYWORDS" || -z "$SELECTION" ]]; then
    log "ERROR: --keywords and --selection are required."
    usage
  fi

  mkdir -p "${OUTPUT_DIR}" || {
    log "ERROR: Failed to create output directory '${OUTPUT_DIR}'"
    exit 1
  }
  
  log "INFO: Downloading music: keywords='${KEYWORDS}', selection='${SELECTION}', output='${OUTPUT_DIR}'"

  # Check for credentials
  if [[ ! -f "${HOME}/.google_oauth_credentials.json" ]]; then
    log "ERROR: Google OAuth credentials not found. Please run setup_google_oauth.sh first."
    exit 1
  fi

  # Use the YouTube Data API with OAuth 2.0 via Python script
  python3 -c "
import os
import sys
import google.oauth2.credentials
import google_auth_oauthlib.flow
import googleapiclient.discovery
import googleapiclient.errors
import json
import subprocess

def download_video(video_id, output_dir):
    url = f'https://www.youtube.com/watch?v={video_id}'
    output_template = os.path.join(output_dir, '%(title)s.%(ext)s')
    
    # Using yt-dlp (more maintained fork of youtube-dl)
    proc = subprocess.Popen(
        ['yt-dlp', '--extract-audio', '--audio-format', 'mp3', 
         '--audio-quality', '0', '-o', output_template, url],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    
    # Stream output to our logging
    for line in proc.stdout:
        print(f'YT-DLP: {line.strip()}')
    
    returncode = proc.wait()
    if returncode != 0:
        for line in proc.stderr:
            print(f'YT-DLP ERROR: {line.strip()}')
        raise Exception(f'Failed to download video {video_id}')
    
    print(f'SUCCESS: Downloaded video {video_id}')

try:
    # Load credentials
    with open(os.path.expanduser('~/.google_oauth_credentials.json'), 'r') as f:
        creds_data = json.load(f)
    
    credentials = google.oauth2.credentials.Credentials(
        token=creds_data.get('token'),
        refresh_token=creds_data.get('refresh_token'),
        token_uri=creds_data.get('token_uri'),
        client_id=creds_data.get('client_id'),
        client_secret=creds_data.get('client_secret')
    )
    
    # Create YouTube API client
    youtube = googleapiclient.discovery.build('youtube', 'v3', credentials=credentials)
    
    # Search for videos
    keywords = '${KEYWORDS}'
    selection = '${SELECTION}'
    output_dir = '${OUTPUT_DIR}'
    
    print(f'INFO: Searching YouTube for \"{keywords}\"')
    request = youtube.search().list(
        part='snippet',
        q=keywords,
        type='video',
        maxResults=10,
        videoCategoryId='10'  # Music category
    )
    response = request.execute()
    
    # Process results based on selection criteria
    if not response.get('items'):
        print('WARNING: No results found')
        sys.exit(0)
    
    selected_video = None
    if selection.lower() == 'first':
        selected_video = response['items'][0]
    elif selection.lower() == 'popular':
        # Get video stats to find the most popular
        video_ids = [item['id']['videoId'] for item in response['items']]
        videos_request = youtube.videos().list(
            part='statistics',
            id=','.join(video_ids)
        )
        videos_response = videos_request.execute()
        
        # Find the video with the most views
        max_views = 0
        max_views_index = 0
        for i, video in enumerate(videos_response['items']):
            views = int(video['statistics'].get('viewCount', 0))
            if views > max_views:
                max_views = views
                max_views_index = i
        
        selected_video = response['items'][max_views_index]
    else:
        # Try to interpret selection as an index
        try:
            index = int(selection) - 1
            if 0 <= index < len(response['items']):
                selected_video = response['items'][index]
            else:
                print(f'ERROR: Selection index {index+1} out of range')
                sys.exit(1)
        except ValueError:
            print(f'ERROR: Unknown selection criteria: {selection}')
            sys.exit(1)
    
    if selected_video:
        video_id = selected_video['id']['videoId']
        video_title = selected_video['snippet']['title']
        print(f'INFO: Selected video: \"{video_title}\" (ID: {video_id})')
        download_video(video_id, output_dir)
    else:
        print('ERROR: Failed to select a video')
        sys.exit(1)
        
except Exception as e:
    print(f'ERROR: {str(e)}')
    sys.exit(1)
" || {
    log "ERROR: Music download failed"
    exit 1
  }

  log "SUCCESS: Music download completed"
}

main "$@"