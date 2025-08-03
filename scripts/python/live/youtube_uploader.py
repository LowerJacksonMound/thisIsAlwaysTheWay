#!/usr/bin/env python3
import logging
import signal
import sys
import argparse
import os
import json
from typing import Protocol, Optional
from pathlib import Path

try:
    import google.auth.transport.requests
    import google.oauth2.credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
    from googleapiclient.http import MediaFileUpload
except ImportError as e:
    logger = logging.getLogger(__name__)
    logger.error(f"Missing required Google API dependencies: {e}")
    logger.error("Please install with: pip install -r requirements.txt")
    sys.exit(1)

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(logging.Formatter('[%(asctime)s] [%(levelname)s] %(message)s'))
logger.addHandler(handler)

def _shutdown(signum, frame):
    logger.info(f'Received signal {signum}, shutting down...')
    sys.exit(0)

signal.signal(signal.SIGINT, _shutdown)
signal.signal(signal.SIGTERM, _shutdown)

SCOPES = ['https://www.googleapis.com/auth/youtube.upload']
API_SERVICE_NAME = 'youtube'
API_VERSION = 'v3'
CLIENT_SECRETS_FILE = 'client_secrets.json'
CREDENTIALS_FILE = 'youtube_credentials.json'

class YouTubeClient(Protocol):
    def upload(self, video_path: str, title: str, description: str, tags: Optional[list] = None, 
               category_id: str = "22", privacy_status: str = "private") -> Optional[str]:
        ...

class RealYouTubeClient:
    def __init__(self, client_secrets_path: str = CLIENT_SECRETS_FILE, 
                 credentials_path: str = CREDENTIALS_FILE):
        self.client_secrets_path = client_secrets_path
        self.credentials_path = credentials_path
        self.youtube = None
        self._authenticate()

    def _authenticate(self):
        credentials = None
        
        if os.path.exists(self.credentials_path):
            try:
                with open(self.credentials_path, 'r') as f:
                    creds_data = json.load(f)
                credentials = google.oauth2.credentials.Credentials.from_authorized_user_info(creds_data, SCOPES)
                logger.info("Loaded existing credentials")
            except Exception as e:
                logger.warning(f"Failed to load existing credentials: {e}")
                credentials = None

        if not credentials or not credentials.valid:
            if credentials and credentials.expired and credentials.refresh_token:
                try:
                    credentials.refresh(google.auth.transport.requests.Request())
                    logger.info("Refreshed expired credentials")
                except Exception as e:
                    logger.warning(f"Failed to refresh credentials: {e}")
                    credentials = None
            
            if not credentials:
                if not os.path.exists(self.client_secrets_path):
                    raise FileNotFoundError(f"Client secrets file not found: {self.client_secrets_path}")
                
                flow = InstalledAppFlow.from_client_secrets_file(self.client_secrets_path, SCOPES)
                credentials = flow.run_local_server(port=0)
                logger.info("Completed OAuth2 flow")

            with open(self.credentials_path, 'w') as f:
                json.dump(credentials.to_json(), f)
            logger.info(f"Saved credentials to {self.credentials_path}")

        self.youtube = build(API_SERVICE_NAME, API_VERSION, credentials=credentials)
        logger.info("YouTube API client initialized successfully")

    def upload(self, video_path: str, title: str, description: str, tags: Optional[list] = None,
               category_id: str = "22", privacy_status: str = "private") -> Optional[str]:
        if not self.youtube:
            raise RuntimeError("YouTube client not initialized")
        
        if not os.path.exists(video_path):
            raise FileNotFoundError(f"Video file not found: {video_path}")
        
        body = {
            'snippet': {
                'title': title,
                'description': description,
                'tags': tags or [],
                'categoryId': category_id
            },
            'status': {
                'privacyStatus': privacy_status,
                'selfDeclaredMadeForKids': False
            }
        }
        
        media = MediaFileUpload(
            video_path,
            chunksize=-1,
            resumable=True
        )
        
        try:
            logger.info(f"Starting upload of '{video_path}' as '{title}'")
            
            insert_request = self.youtube.videos().insert(
                part=','.join(body.keys()),
                body=body,
                media_body=media
            )
            
            response = None
            while response is None:
                status, response = insert_request.next_chunk()
                if status:
                    logger.info(f"Upload progress: {int(status.progress() * 100)}%")
            
            video_id = response['id']
            video_url = f"https://www.youtube.com/watch?v={video_id}"
            
            logger.info(f"Upload completed successfully!")
            logger.info(f"Video ID: {video_id}")
            logger.info(f"Video URL: {video_url}")
            
            return video_id
            
        except HttpError as e:
            logger.error(f"YouTube API error: {e}")
            raise
        except Exception as e:
            logger.error(f"Upload failed: {e}")
            raise

class MockYouTubeClient:
    def __init__(self):
        logger.info("Initializing MockYouTubeClient")

    def upload(self, video_path: str, title: str, description: str, tags: Optional[list] = None,
               category_id: str = "22", privacy_status: str = "private") -> Optional[str]:
        logger.info(f"[MOCK] Pretending to upload '{video_path}' as '{title}'")
        logger.info(f"[MOCK] Description: {description}")
        logger.info(f"[MOCK] Tags: {tags}")
        logger.info(f"[MOCK] Category: {category_id}, Privacy: {privacy_status}")
        mock_video_id = "mock_video_123"
        logger.info(f"[MOCK] Generated video ID: {mock_video_id}")
        return mock_video_id

def upload_video(client: YouTubeClient, video_path: str, title: str, description: str,
                tags: Optional[list] = None, category_id: str = "22", 
                privacy_status: str = "private") -> Optional[str]:
    return client.upload(video_path, title, description, tags, category_id, privacy_status)

def main():
    parser = argparse.ArgumentParser(description="YouTube Uploader with OAuth2 Authentication")
    parser.add_argument('-p', '--path', required=True, help='Path to video file')
    parser.add_argument('-t', '--title', required=True, help='Video title')
    parser.add_argument('-d', '--desc', default='', help='Video description')
    parser.add_argument('--tags', nargs='*', help='Video tags (space-separated)')
    parser.add_argument('--category', default='22', help='YouTube category ID (default: 22 - People & Blogs)')
    parser.add_argument('--privacy', choices=['private', 'public', 'unlisted'], 
                       default='private', help='Privacy status (default: private)')
    parser.add_argument('--mock', action='store_true', help='Use mock YouTube client')
    parser.add_argument('--client-secrets', default=CLIENT_SECRETS_FILE, 
                       help='Path to client secrets JSON file')
    parser.add_argument('--credentials', default=CREDENTIALS_FILE,
                       help='Path to store/load credentials')
    
    args = parser.parse_args()

    if not args.mock and not os.path.exists(args.path):
        logger.error(f"Video file not found: {args.path}")
        sys.exit(1)

    if args.mock:
        client = MockYouTubeClient()
    else:
        try:
            client = RealYouTubeClient(args.client_secrets, args.credentials)
        except Exception as e:
            logger.error(f"Failed to initialize YouTube client: {e}")
            sys.exit(1)

    try:
        video_id = upload_video(
            client=client,
            video_path=args.path,
            title=args.title,
            description=args.desc,
            tags=args.tags,
            category_id=args.category,
            privacy_status=args.privacy
        )
        
        if video_id and not args.mock:
            logger.info(f"Success! Video uploaded with ID: {video_id}")
            logger.info(f"Watch at: https://www.youtube.com/watch?v={video_id}")
        
    except Exception:
        logger.exception("Error in youtube_uploader")
        sys.exit(1)

if __name__ == "__main__":
    main()
