#!/usr/bin/env python3
import os
import sys
import signal
import logging
import argparse
import requests
from dotenv import load_dotenv

def setup_logging():
    logger = logging.getLogger('pixabay_audio_downloader')
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

class PixabayAudioDownloader:
    def __init__(self):
        load_dotenv()
        self.api_key = os.getenv('PIXABAY_API_KEY')
        if not self.api_key:
            logger.error('PIXABAY_API_KEY not set')
            sys.exit(1)
        self.base_url = 'https://pixabay.com/api/'

    def download(self, query: str, per_page: int = 3):
        params = {'key': self.api_key, 'q': query, 'audio_type': 'music', 'per_page': per_page}
        response = requests.get(self.base_url, params=params)
        response.raise_for_status()
        hits = response.json().get('hits', [])
        files = []
        for hit in hits:
            url = hit.get('audio_url')
            filename = os.path.basename(url)
            r = requests.get(url)
            r.raise_for_status()
            with open(filename, 'wb') as f:
                f.write(r.content)
            logger.info(f"Downloaded {filename}")
            files.append(filename)
        return files

def parse_args():
    parser = argparse.ArgumentParser(description="Download audio clips from Pixabay")
    parser.add_argument('-q', '--query', required=True, help='Search term')
    parser.add_argument('-n', '--num', type=int, default=3, help='Number of audio files')
    return parser.parse_args()

def main():
    args = parse_args()
    downloader = PixabayAudioDownloader()
    try:
        files = downloader.download(args.query, args.num)
        logger.info(f"Downloaded files: {files}")
    except Exception:
        logger.exception("Error downloading audio")
        sys.exit(1)

if __name__ == '__main__':
    main()
