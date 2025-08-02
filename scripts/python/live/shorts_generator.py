#!/usr/bin/env python3
import os
import sys
import signal
import logging
import argparse
from typing import Protocol
from moviepy.editor import VideoFileClip

def setup_logging():
    logger = logging.getLogger('shorts_generator')
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
    # Kill any potential moviepy subprocesses
    os.killpg(os.getpgid(0), signal.SIGTERM)
    sys.exit(0)

signal.signal(signal.SIGTERM, handle_signal)
signal.signal(signal.SIGINT, handle_signal)

class ShortsClient(Protocol):
    def generate(self, input_video: str, length: int) -> str:
        ...

class RealShortsClient:
    def generate(self, input_video: str, length: int) -> str:
        if not os.path.exists(input_video):
            logger.error(f"Input video not found: {input_video}")
            raise FileNotFoundError(f"Input video not found: {input_video}")
        
        logger.info(f"[REAL] Generating short from '{input_video}' ({length}s)")
        try:
            clip = VideoFileClip(input_video).subclip(0, length)
            output_path = os.path.abspath(f"short_{os.path.basename(input_video)}")
            clip.write_videofile(output_path, codec="libx264", audio_codec="aac")
            logger.info(f"Short video created at {output_path}")
            return output_path
        except Exception as e:
            logger.exception(f"Error generating short: {str(e)}")
            raise

class MockShortsClient:
    def __init__(self):
        logger.info("Initializing MockShortsClient")
    
    def generate(self, input_video: str, length: int) -> str:
        logger.info(f"[MOCK] Pretending to generate {length}s short from '{input_video}'")
        return f"mock_short_{os.path.basename(input_video)}"

def generate_short(client: ShortsClient, input_video: str, length: int) -> str:
    return client.generate(input_video, length)

def parse_args():
    parser = argparse.ArgumentParser(description="Generate a short clip from a video")
    parser.add_argument('-p', '--path', required=True, help='Path to input video')
    parser.add_argument('-l', '--length', type=int, default=15, help='Length in seconds')
    parser.add_argument('--mock', action='store_true', help='Use mock Shorts client')
    return parser.parse_args()

def main():
    args = parse_args()
    client = MockShortsClient() if args.mock else RealShortsClient()
    try:
        output_path = generate_short(client, args.path, args.length)
        logger.info(f"Generated short: {output_path}")
    except Exception:
        logger.exception("Error generating short")
        sys.exit(1)

if __name__ == '__main__':
    main()