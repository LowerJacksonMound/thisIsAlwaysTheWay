#!/usr/bin/env python3
import os
import json
import logging
from google_auth_oauthlib.flow import InstalledAppFlow
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request

logger = logging.getLogger('google_auth')

def get_authenticated_service(api_name, api_version, scopes):
    """Get an authenticated service for Google APIs using OAuth 2.0."""
    creds = None
    token_file = f'token_{api_name}.json'
    
    # Load credentials from file if they exist
    if os.path.exists(token_file):
        try:
            with open(token_file, 'r') as token:
                creds = Credentials.from_authorized_user_info(json.loads(token.read()), scopes)
        except Exception as e:
            logger.warning(f"Error loading credentials: {e}")
    
    # If credentials don't exist or are invalid, get new ones
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            logger.info("Refreshing expired credentials")
            creds.refresh(Request())
        else:
            logger.info("Getting new credentials")
            secrets_file = os.getenv('GOOGLE_CLIENT_SECRETS_FILE', 'client_secrets.json')
            if not os.path.exists(secrets_file):
                raise FileNotFoundError(f"Client secrets file not found: {secrets_file}")
                
            flow = InstalledAppFlow.from_client_secrets_file(secrets_file, scopes)
            creds = flow.run_local_server(port=0)
            
        # Save credentials for next run
        with open(token_file, 'w') as token:
            token.write(creds.to_json())
    
    from googleapiclient.discovery import build
    return build(api_name, api_version, credentials=creds)