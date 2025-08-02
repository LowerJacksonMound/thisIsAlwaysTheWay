#!/usr/bin/env python3
import logging
import signal
import sys
import argparse
from typing import Protocol

# --- Logging Setup ---
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(logging.Formatter('[%(asctime)s] [%(levelname)s] %(message)s'))
logger.addHandler(handler)

# --- Shutdown Handling ---
def _shutdown(signum, frame):
    logger.info(f'Received signal {{signum}}, shutting down...')
    sys.exit(0)

signal.signal(signal.SIGINT, _shutdown)
signal.signal(signal.SIGTERM, _shutdown)

# --- API Client Protocols for Mocking ---
class LinkedInClient(Protocol):
    def post_video(self, video_path: str) -> None:
        ...

class RealLinkedInClient:
    def __init__(self):
        # TODO: initialize LinkedIn API client
        pass

    def post_video(self, video_path: str) -> None:
        logger.info(f"[REAL] Posting '{{video_path}}' to LinkedIn")
        # TODO: call LinkedIn V2 API endpoint

class MockLinkedInClient:
    def __init__(self):
        logger.info("Initializing MockLinkedInClient")

    def post_video(self, video_path: str) -> None:
        logger.info(f"[MOCK] Pretending to post '{{video_path}}' to LinkedIn")

# --- Core Functionality ---
def post_video(client: LinkedInClient, video_path: str) -> None:
    client.post_video(video_path)

# --- Entry Point ---
def main():
    parser = argparse.ArgumentParser(description="LinkedIn Video Poster with Mock Support")
    parser.add_argument('-p', '--path', required=True, help='Path to video file')
    parser.add_argument('--mock', action='store_true', help='Use mock LinkedIn client')
    args = parser.parse_args()

    client = MockLinkedInClient() if args.mock else RealLinkedInClient()

    try:
        post_video(client, args.path)
    except Exception:
        logger.exception("Error in linkedin_poster")
        sys.exit(1)

if __name__ == "__main__":
    main()
