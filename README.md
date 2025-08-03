# YouTube Uploader - Production Implementation

This repository contains both mocked and production versions of a YouTube uploader with Google OAuth2 authentication and YouTube Data API integration.

## Structure

- `scripts/python/live/youtube_uploader.py` - Production version with real YouTube API integration
- `requirements.txt` - Python dependencies for the production version

## Features

### Production Version (`scripts/python/live/youtube_uploader.py`)

- **OAuth2 Authentication**: Secure authentication with Google using OAuth2 flow
- **Resumable Uploads**: Handles large video files with resumable upload capability
- **Credential Caching**: Saves and reuses authentication credentials
- **Flexible Configuration**: Supports custom titles, descriptions, tags, categories, and privacy settings
- **Mock Mode**: Includes mock client for testing without actual uploads
- **Progress Tracking**: Shows upload progress for large files
- **Error Handling**: Comprehensive error handling and logging

## Setup

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Google Cloud Console Setup

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the YouTube Data API v3:
   - Go to "APIs & Services" > "Library"
   - Search for "YouTube Data API v3"
   - Click "Enable"

### 3. Create OAuth2 Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Choose "Desktop application"
4. Download the JSON file and save it as `client_secrets.json`

## Usage

### Basic Upload (Private)

```bash
cd scripts/python/live
python youtube_uploader.py -p /path/to/video.mp4 -t "My Video Title" -d "Video description"
```

### Public Upload with Tags

```bash
python youtube_uploader.py \
  -p /path/to/video.mp4 \
  -t "My Public Video" \
  -d "This is a public video" \
  --tags "tag1" "tag2" "tag3" \
  --privacy public \
  --category 22
```

### Mock Mode (Testing)

```bash
python youtube_uploader.py --mock -p /path/to/video.mp4 -t "Test Video"
```

## Command Line Arguments

- `-p, --path`: Path to video file (required)
- `-t, --title`: Video title (required)
- `-d, --desc`: Video description (optional)
- `--tags`: Space-separated list of tags (optional)
- `--category`: YouTube category ID (default: 22 - People & Blogs)
- `--privacy`: Privacy status - private, public, or unlisted (default: private)
- `--mock`: Use mock client for testing
- `--client-secrets`: Path to client secrets JSON file
- `--credentials`: Path to store/load credentials

## Authentication Flow

### First Run
1. Application checks for existing credentials in `youtube_credentials.json`
2. If not found, initiates OAuth2 flow
3. Opens browser for user to authenticate with Google
4. User grants permission for YouTube upload access
5. Credentials are saved locally for future use

### Subsequent Runs
1. Application loads saved credentials
2. If expired, automatically refreshes using refresh token
3. If refresh fails, re-initiates OAuth2 flow

## Security Notes

- Keep `client_secrets.json` secure and never commit to version control
- The `youtube_credentials.json` file contains sensitive tokens - protect accordingly
- Use environment variables for production deployments

## Differences from Mock Version

The production version enhances the original mock implementation with:

- **Complete OAuth2 Implementation**: Full Google authentication flow
- **YouTube Data API Integration**: Real API calls with proper error handling
- **Resumable Uploads**: Handles large files efficiently
- **Credential Management**: Automatic token refresh and storage
- **Enhanced Configuration**: More upload options (tags, categories, privacy)
- **Progress Tracking**: Upload progress reporting
- **Comprehensive Error Handling**: Detailed error messages and recovery
- **Security Best Practices**: Proper credential handling and validation
