#!/usr/bin/env python3
import os
import sys
import signal
import logging
import argparse
from dotenv import load_dotenv
from typing import Protocol
from google_auth_utils import get_authenticated_service
from googleapiclient.http import MediaFileUpload

def setup_logging():
    logger = logging.getLogger('youtube_uploader')
    logger.setLevel(logging.INFO)
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(logging.Formatter(
        '[%(asctime)s] [%(process)d] %(levelname)s] %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'))
    logger.addHandler(handler)
    return logger

logger = setup_logging()

def handle_signal(signum, frame):
    logger.info(f"Received signal {signum}, exiting.")
    sys.exit(0)

signal.signal(signal.SIGTERM, handle_signal)
signal.signal(signal.SIGINT, handle_signal)

class YouTubeClient(Protocol):
    def upload(self, video_path: str, title: str, description: str) -> str:
        ...

class RealYouTubeClient:
    def __init__(self):
        load_dotenv()
        # YouTube upload requires OAuth with specific scopes
        SCOPES = ['https://www.googleapis.com/auth/youtube.upload']
        try:
            self.youtube = get_authenticated_service('youtube', 'v3', SCOPES)
        except Exception as e:
            logger.error(f"Failed to authenticate with YouTube API: {e}")
            sys.exit(1)

    def upload(self, video_path: str, title: str, description: str) -> str:
        if not os.path.exists(video_path):
            logger.error(f"Video file not found: {video_path}")
            sys.exit(1)
        try:
            logger.info(f"Uploading '{video_path}' as '{title}'")
            body = {
                'snippet': {'title': title, 'description': description},
                'status': {'privacyStatus': 'public'}
            }
            media = MediaFileUpload(video_path, chunksize=-1, resumable=True)
            request = self.youtube.videos().insert(
                part='snippet,status', body=body, media_body=media
            )
            response = None
            while response is None:
                status, response = request.next_chunk()
                if status:
                    logger.info(f"Upload progress: {int(status.progress() * 100)}%")
            video_id = response.get('id')
            logger.info(f"Video uploaded successfully with ID: {video_id}")
            return video_id
        except Exception:
            logger.exception("Failed to upload video to YouTube")
            raise

class MockYouTubeClient:
    def __init__(self):
        logger.info("Initializing MockYouTubeClient")
    
    def upload(self, video_path: str, title: str, description: str) -> str:
        logger.info(f"[MOCK] Pretending to upload '{video_path}' as '{title}'")
        return "mock_video_id_12345"

def upload_video(client: YouTubeClient, video_path: str, title: str, description: str) -> str:
    return client.upload(video_path, title, description)

def parse_args():
    parser = argparse.ArgumentParser(description="Upload a video to YouTube")
    parser.add_argument('-p', '--path', required=True, help='Video file path')
    parser.add_argument('-t', '--title', required=True, help='Video title')
    parser.add_argument('-d', '--desc', default='', help='Video description')
    parser.add_argument('--mock', action='store_true', help='Use mock YouTube client')
    return parser.parse_args()

def main():
    args = parse_args()
    client = MockYouTubeClient() if args.mock else RealYouTubeClient()
    try:
        video_id = upload_video(client, args.path, args.title, args.desc)
        logger.info(f"Video ID: {video_id}")
    except Exception:
        sys.exit(1)

if __name__ == '__main__':
    main()