#!/usr/bin/env python3
import os
import sys
import signal
import logging
import argparse
from dotenv import load_dotenv
from typing import Protocol, List
from PIL import Image
import pytesseract

def setup_logging():
    logger = logging.getLogger('frame_prompt_extractor')
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

class ExtractorClient(Protocol):
    def extract(self, frame_path: str) -> List[str]:
        ...

class RealExtractorClient:
    def __init__(self):
        load_dotenv()

    def extract(self, frame_path: str) -> List[str]:
        logger.info(f"[REAL] Extracting prompts from '{frame_path}'")
        if not os.path.exists(frame_path):
            logger.error(f"Frame path does not exist: {frame_path}")
            return []
        text = pytesseract.image_to_string(Image.open(frame_path))
        prompts = [line for line in text.splitlines() if line.strip()]
        return prompts

class MockExtractorClient:
    def __init__(self):
        logger.info("Initializing MockExtractorClient")

    def extract(self, frame_path: str) -> List[str]:
        logger.info(f"[MOCK] Pretending to extract prompts from '{frame_path}'")
        return ["example prompt 1", "example prompt 2"]

def extract_prompts_from_frame(client: ExtractorClient, frame_path: str) -> List[str]:
    return client.extract(frame_path)

def parse_args():
    parser = argparse.ArgumentParser(description="Frame Prompt Extractor with Mock Support")
    parser.add_argument('-p', '--path', required=True, help='Path to frame image')
    parser.add_argument('--mock', action='store_true', help='Use mock Extractor client')
    return parser.parse_args()

def main():
    args = parse_args()
    client = MockExtractorClient() if args.mock else RealExtractorClient()
    try:
        prompts = extract_prompts_from_frame(client, args.path)
        logger.info(f"Extracted prompts: {prompts}")
    except Exception:
        logger.exception("Error in frame_prompt_extractor")
        sys.exit(1)

if __name__ == "__main__":
    main()
