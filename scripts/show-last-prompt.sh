#!/bin/bash
# Show the last user prompt sent to Claude API
# Usage: ./show-last-prompt.sh [flow-file]

FLOW_FILE="${1:-$HOME/claude-flows.mitm}"

if [ ! -f "$FLOW_FILE" ]; then
    echo "No flow file found at: $FLOW_FILE"
    exit 1
fi

echo "Extracting last user prompt from: $FLOW_FILE"
echo "================================================================"

mitmdump -r "$FLOW_FILE" -s - <<'PYTHON'
import json
from mitmproxy import http

last_user_message = None

def response(flow: http.HTTPFlow):
    global last_user_message

    if "api.anthropic.com" not in flow.request.pretty_url:
        return

    try:
        data = json.loads(flow.request.content.decode('utf-8'))
        messages = data.get('messages', [])

        # Find last user message
        for msg in reversed(messages):
            if msg.get('role') == 'user':
                content = msg.get('content', [])
                if isinstance(content, str):
                    last_user_message = content
                elif isinstance(content, list):
                    text = '\n'.join([c.get('text', '') for c in content if c.get('type') == 'text'])
                    last_user_message = text
                break
    except:
        pass

def done():
    if last_user_message:
        print(last_user_message)
    else:
        print("No user messages found")
PYTHON
