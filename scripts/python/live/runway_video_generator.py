#!/usr/bin/env python3
import os
import logging
import signal
import sys
import argparse
import asyncio
import requests
from dotenv import load_dotenv
from typing import Protocol, Awaitable

# --- Logging Setup ---
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(logging.Formatter('[%(asctime)s] [%(levelname)s] %(message)s'))
logger.addHandler(handler)

# --- Shutdown Handling ---
def _shutdown(signum, frame):
    logger.info(f"Received signal {signum}, shutting down...")
    sys.exit(0)

signal.signal(signal.SIGTERM, _shutdown)

# --- Runway Client Protocols for Mocking ---
class RunwayClient(Protocol):
    async def generate(self, prompt: str) -> bytes:
        ...

class RealRunwayClient:
    def __init__(self, api_url: str = None, api_key: str = None):
        load_dotenv()
        self.api_key = api_key or os.getenv('RUNWAY_API_KEY')
        self.api_url = api_url or os.getenv('RUNWAY_API_URL', 'https://api.runwayml.com/v1/generate')
        if not self.api_key:
            logger.error('RUNWAY_API_KEY not set')
            sys.exit(1)

    async def generate(self, prompt: str) -> bytes:
        logger.info(f"[REAL] Generating video for prompt '{prompt}'")
        response = requests.post(
            self.api_url,
            json={'prompt': prompt},
            headers={'Authorization': f'Bearer {self.api_key}'}
        )
        response.raise_for_status()
        return response.content

class MockRunwayClient:
    def __init__(self):
        logger.info("Initializing MockRunwayClient")

    async def generate(self, prompt: str) -> bytes:
        logger.info(f"[MOCK] Pretending to generate video for '{prompt}'")
        return b''

async def generate_with_runway(client: RunwayClient, prompt: str) -> bytes:
    return await client.generate(prompt)

async def _async_main():
    parser = argparse.ArgumentParser(description="Runway Video Generator with Mock Support")
    parser.add_argument('-p', '--prompt', required=True, help='Text prompt for video generation')
    parser.add_argument('--mock', action='store_true', help='Use mock Runway client')
    args = parser.parse_args()

    client = MockRunwayClient() if args.mock else RealRunwayClient()
    try:
        video = await generate_with_runway(client, args.prompt)
        output_path = os.getenv('OUTPUT_VIDEO_PATH', 'output.mp4')
        with open(output_path, 'wb') as f:
            f.write(video)
        logger.info(f"Saved video to {output_path}")
    except Exception:
        logger.exception("Error in runway_video_generator")
        sys.exit(1)

def main():
    asyncio.run(_async_main())

if __name__ == "__main__":
    main()
