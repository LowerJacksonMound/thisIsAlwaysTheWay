#!/usr/bin/env python3
import os
import logging
import signal
import sys
import argparse
import asyncio
from dotenv import load_dotenv
from typing import Protocol

# --- Logging Setup ---
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(logging.Formatter('[%(asctime)s] [%(levelname)s] %(message)s'))
logger.addHandler(handler)

# --- Shutdown Handling ---
def _shutdown(signum, frame):
    logger.info(f"Received signal {signum}, shutting down...")
    # Force termination of any potential child processes
    os.killpg(os.getpgid(0), signal.SIGTERM)
    sys.exit(0)

signal.signal(signal.SIGTERM, _shutdown)

# --- Import Components ---
from frame_prompt_extractor import RealExtractorClient, extract_prompts_from_frame
from runway_video_generator import RealRunwayClient, generate_with_runway
from youtube_uploader import RealYouTubeClient, upload_video
from engagement_tracker import RealAnalyticsClient, fetch_metrics
from shorts_generator import RealShortsClient, generate_short
from linkedin_poster import RealLinkedInClient, post_video
from comment_responder import RealCommentClient, respond_to_comment

# --- Automator Protocol for Mocking ---
class Automator(Protocol):
    def run(self) -> None:
        ...

class RealYouTubeAutomator:
    def __init__(self):
        load_dotenv()
        self.frame_path = os.getenv('FRAME_PATH')
        self.video_id = os.getenv('VIDEO_ID')
        self.comment_id = os.getenv('COMMENT_ID')

        self.extractor = RealExtractorClient()
        self.runway = RealRunwayClient()
        self.uploader = RealYouTubeClient()
        self.analytics = RealAnalyticsClient()
        self.shorts = RealShortsClient()
        self.linkedin = RealLinkedInClient()
        self.commenter = RealCommentClient()

    def run(self) -> None:
        if not self.frame_path:
            logger.error("FRAME_PATH not set")
            sys.exit(1)
        prompts = extract_prompts_from_frame(self.extractor, self.frame_path)
        prompt = prompts[0] if prompts else ""
        video_bytes = asyncio.run(generate_with_runway(self.runway, prompt))
        video_path = os.getenv('OUTPUT_VIDEO_PATH', 'output_video.mp4')
        with open(video_path, 'wb') as f:
            f.write(video_bytes)
        title = os.getenv('VIDEO_TITLE', 'Generated Video')
        desc = os.getenv('VIDEO_DESC', '')
        upload_video(self.uploader, video_path, title, desc)
        if self.video_id:
            metrics = fetch_metrics(self.analytics, self.video_id)
            logger.info(f"Metrics: {metrics}")
        short_len = int(os.getenv('SHORT_LENGTH', '15'))
        short_path = generate_short(self.shorts, video_path, short_len)
        post_video(self.linkedin, short_path)
        if self.comment_id:
            text = os.getenv('COMMENT_TEXT', 'Thanks for watching!')
            respond_to_comment(self.commenter, self.comment_id, text)

class MockYouTubeAutomator:
    def __init__(self):
        logger.info("Initializing MockYouTubeAutomator")

    def run(self) -> None:
        logger.info("[MOCK] Pretending to run YouTube automation workflow")

def main():
    parser = argparse.ArgumentParser(description="YouTube Automator with Mock Support")
    parser.add_argument('--mock', action='store_true', help='Use mock Automator')
    args = parser.parse_args()

    automator = MockYouTubeAutomator() if args.mock else RealYouTubeAutomator()
    try:
        automator.run()
    except Exception:
        logger.exception("Error in youtube_automator")
        sys.exit(1)

if __name__ == "__main__":
    main()