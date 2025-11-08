#!/usr/bin/env python3
"""
Extract slash command expansions from captured mitmproxy flows.
Usage: mitmdump -r flows.mitm -s extract-slash-commands.py
"""

import json
from mitmproxy import http

def response(flow: http.HTTPFlow):
    """Process each flow and extract user messages (slash command expansions)"""

    if "api.anthropic.com" not in flow.request.pretty_url:
        return

    try:
        # Parse request body
        request_data = json.loads(flow.request.content.decode('utf-8'))

        # Extract messages
        messages = request_data.get('messages', [])

        for i, msg in enumerate(messages):
            if msg.get('role') == 'user':
                content = msg.get('content', [])

                # Handle both string and array content formats
                if isinstance(content, str):
                    text = content
                elif isinstance(content, list):
                    text_parts = [c.get('text', '') for c in content if c.get('type') == 'text']
                    text = '\n'.join(text_parts)
                else:
                    continue

                # Print user message with separator
                print(f"\n{'='*80}")
                print(f"USER MESSAGE #{i+1}")
                print(f"{'='*80}")
                print(text)
                print(f"{'='*80}\n")

    except Exception as e:
        print(f"Error processing flow: {e}")
