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
class CommentClient(Protocol):
    def respond(self, comment_id: str, text: str) -> None:
        ...

class RealCommentClient:
    def __init__(self):
        # TODO: initialize YouTube commentThreads API client
        pass

    def respond(self, comment_id: str, text: str) -> None:
        logger.info(f"[REAL] Responding to '{{comment_id}}' with '{{text}}'")
        # TODO: call commentThreads.insert()

class MockCommentClient:
    def __init__(self):
        logger.info("Initializing MockCommentClient")

    def respond(self, comment_id: str, text: str) -> None:
        logger.info(f"[MOCK] Pretending to respond to '{{comment_id}}' with '{{text}}'")

# --- Core Functionality ---
def respond_to_comment(client: CommentClient, comment_id: str, text: str) -> None:
    client.respond(comment_id, text)

# --- Entry Point ---
def main():
    parser = argparse.ArgumentParser(description="Comment Responder with Mock Support")
    parser.add_argument('-i', '--id', required=True, help='Comment ID')
    parser.add_argument('-t', '--text', required=True, help='Response text')
    parser.add_argument('--mock', action='store_true', help='Use mock Comment client')
    args = parser.parse_args()

    client = MockCommentClient() if args.mock else RealCommentClient()

    try:
        respond_to_comment(client, args.id, args.text)
    except Exception:
        logger.exception("Error in comment_responder")
        sys.exit(1)

if __name__ == "__main__":
    main()
