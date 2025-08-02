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
class AnalyticsClient(Protocol):
    def fetch_metrics(self, video_id: str) -> dict:
        ...

class RealAnalyticsClient:
    def __init__(self):
        # TODO: initialize YouTube Analytics API client
        pass

    def fetch_metrics(self, video_id: str) -> dict:
        logger.info(f"[REAL] Fetching metrics for '{{video_id}}'")
        # TODO: call analytics API
        return {}

class MockAnalyticsClient:
    def __init__(self):
        logger.info("Initializing MockAnalyticsClient")

    def fetch_metrics(self, video_id: str) -> dict:
        logger.info(f"[MOCK] Pretending to fetch metrics for '{{video_id}}'")
        return {"views": 0, "likes": 0, "comments": 0}

# --- Core Functionality ---
def fetch_metrics(client: AnalyticsClient, video_id: str) -> dict:
    return client.fetch_metrics(video_id)

# --- Entry Point ---
def main():
    parser = argparse.ArgumentParser(description="Engagement Tracker with Mock Support")
    parser.add_argument('-i', '--id', required=True, help='Video ID')
    parser.add_argument('--mock', action='store_true', help='Use mock Analytics client')
    args = parser.parse_args()

    client = MockAnalyticsClient() if args.mock else RealAnalyticsClient()

    try:
        metrics = fetch_metrics(client, args.id)
        logger.info(f"Metrics: {metrics}")
    except Exception:
        logger.exception("Error in engagement_tracker")
        sys.exit(1)

if __name__ == "__main__":
    main()
