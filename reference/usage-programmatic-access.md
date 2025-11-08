# Programmatic Access to Captured Traffic

This guide explains how to programmatically analyze captured API traffic while mitmweb or mitmproxy is running, enabling automated extraction of system prompts, slash command expansions, token usage statistics, and other API data.

## Overview

mitmproxy supports multiple interaction modes:

1. **Web UI Only** - Manual inspection via browser (http://localhost:8081)
2. **Programmatic Access** - Automated analysis using Python scripts and CLI tools
3. **Hybrid Mode** - Both web UI and programmatic access simultaneously

## Enabling Programmatic Access

To enable programmatic access while using mitmweb, start it with flow saving:

```bash
mitmweb --web-port 8081 \
        --set flow_filter='~d api.anthropic.com' \
        --save-stream-file ~/claude-flows.mitm
```

**Key differences:**

| Mode | Command | Web UI | Programmatic | Use Case |
|------|---------|--------|--------------|----------|
| Web only | `mitmweb --web-port 8081` | ✅ | ❌ | Manual exploration |
| Programmatic | `mitmdump -w flows.mitm` | ❌ | ✅ | Headless automation |
| Hybrid | `mitmweb --save-stream-file flows.mitm` | ✅ | ✅ | Interactive + automation |

## Bundled Analysis Scripts

### 1. Extract Slash Command Expansions

**Script**: `~/.claude/skills/cc-trace/scripts/extract-slash-commands.py`

Shows how slash commands are expanded with arguments before being sent to the API.

**Usage**:
```bash
mitmdump -r ~/claude-flows.mitm -s ~/.claude/skills/cc-trace/scripts/extract-slash-commands.py
```

**Output**:
```
================================================================================
USER MESSAGE #1
================================================================================
Review the JSON file at /Users/alex/.../extraction.json and process files in /Users/alex/.../output/...
================================================================================
```

**What it does**:
- Parses all flows in the capture file
- Extracts user messages from the `messages` array
- Displays the complete expanded prompt text
- Handles both string and array content formats

### 2. Show Last User Prompt

**Script**: `~/.claude/skills/cc-trace/scripts/show-last-prompt.sh`

Quickly displays the most recent prompt sent to the API.

**Usage**:
```bash
~/.claude/skills/cc-trace/scripts/show-last-prompt.sh
# Or specify a different flow file:
~/.claude/skills/cc-trace/scripts/show-last-prompt.sh /path/to/flows.mitm
```

**Output**:
```
Extracting last user prompt from: /Users/alex/claude-flows.mitm
================================================================
Review the JSON file at /Users/alex/.../extraction.json...
```

**Use cases**:
- Debug slash command argument substitution
- Verify what prompt was actually sent
- Compare expected vs actual input

### 3. Parse Streamed Responses

**Script**: `~/.claude/skills/cc-trace/scripts/parse-streamed-response.ts`

Parses Anthropic's Server-Sent Events (SSE) streaming format into readable output.

**Usage**:
```bash
# Copy response from mitmweb, then:
pbpaste | npx tsx ~/.claude/skills/cc-trace/scripts/parse-streamed-response.ts
```

**Output**: Extracted text content and tool calls from the stream.

## Custom Analysis with mitmdump

### Reading Saved Flows

```bash
# View all flows
mitmdump -r ~/claude-flows.mitm

# View with detailed info
mitmdump -r ~/claude-flows.mitm --flow-detail 2

# Filter specific flows
mitmdump -r ~/claude-flows.mitm -n "~d api.anthropic.com & ~m POST"
```

### Writing Custom Python Scripts

Create a Python script that runs on each flow:

**Example**: Extract token usage statistics

```python
# save as: token-stats.py
import json
from mitmproxy import http

total_input = 0
total_output = 0

def response(flow: http.HTTPFlow):
    global total_input, total_output

    if "api.anthropic.com" not in flow.request.pretty_url:
        return

    try:
        data = json.loads(flow.response.content.decode('utf-8'))
        usage = data.get('usage', {})

        input_tokens = usage.get('input_tokens', 0)
        output_tokens = usage.get('output_tokens', 0)

        total_input += input_tokens
        total_output += output_tokens

        print(f"Request: {input_tokens} in, {output_tokens} out")
    except:
        pass

def done():
    print(f"\nTotal: {total_input} input tokens, {total_output} output tokens")
```

**Run it**:
```bash
mitmdump -r ~/claude-flows.mitm -s token-stats.py
```

### Extracting System Prompts

```python
# save as: extract-system-prompt.py
import json
from mitmproxy import http

def response(flow: http.HTTPFlow):
    if "api.anthropic.com" not in flow.request.pretty_url:
        return

    try:
        data = json.loads(flow.request.content.decode('utf-8'))
        system = data.get('system', '')

        if system:
            print("="*80)
            print("SYSTEM PROMPT")
            print("="*80)
            print(system)
            print("="*80)
    except:
        pass
```

### Extracting Tool Definitions

```python
# save as: extract-tools.py
import json
from mitmproxy import http

seen_tools = set()

def response(flow: http.HTTPFlow):
    if "api.anthropic.com" not in flow.request.pretty_url:
        return

    try:
        data = json.loads(flow.request.content.decode('utf-8'))
        tools = data.get('tools', [])

        for tool in tools:
            name = tool.get('name')
            if name and name not in seen_tools:
                seen_tools.add(name)
                print(f"\nTool: {name}")
                print(f"Description: {tool.get('description', 'N/A')}")
    except:
        pass
```

## Real-Time Analysis

When using `--save-stream-file`, flows are written as they're captured, enabling real-time analysis:

```bash
# Terminal 1: Start mitmweb with flow saving
mitmweb --web-port 8081 --save-stream-file ~/claude-flows.mitm

# Terminal 2: Run Claude Code with proxy
proxy_claude

# Terminal 3: Monitor flows in real-time
watch -n 1 'mitmdump -r ~/claude-flows.mitm -s token-stats.py 2>/dev/null | tail -5'
```

## Exporting Flows from Web UI

If you started mitmweb without `--save-stream-file`, you can export manually:

1. Open mitmweb: http://localhost:8081
2. Click "≡" menu (top right)
3. File → Save
4. Save as `~/captured-flows.mitm`
5. Analyze: `mitmdump -r ~/captured-flows.mitm -s script.py`

**Export formats**:
- `.mitm` - Native mitmproxy format (recommended)
- `.har` - HTTP Archive format (for compatibility)

## Common Analysis Tasks

### Task: Find slash command expansion

```bash
# Use the bundled script
~/.claude/skills/cc-trace/scripts/show-last-prompt.sh
```

### Task: Compare token usage across requests

```bash
mitmdump -r ~/claude-flows.mitm -s token-stats.py
```

### Task: Extract all tool calls

```python
# save as: extract-tool-calls.py
import json
from mitmproxy import http

def response(flow: http.HTTPFlow):
    if "api.anthropic.com" not in flow.request.pretty_url:
        return

    try:
        data = json.loads(flow.response.content.decode('utf-8'))

        # Handle streaming response
        if flow.response.content.startswith(b'event:'):
            # This is SSE format - use parse-streamed-response.ts instead
            return

        content = data.get('content', [])
        for block in content:
            if block.get('type') == 'tool_use':
                print(f"\nTool: {block.get('name')}")
                print(f"Input: {json.dumps(block.get('input', {}), indent=2)}")
    except:
        pass
```

### Task: Search for specific patterns

```bash
# Find all requests mentioning "slash command"
mitmdump -r ~/claude-flows.mitm | grep -i "slash command"

# Extract requests with large token counts
mitmdump -r ~/claude-flows.mitm -s - <<'PYTHON'
import json
from mitmproxy import http

def response(flow):
    try:
        data = json.loads(flow.response.content)
        tokens = data.get('usage', {}).get('input_tokens', 0)
        if tokens > 10000:
            print(f"Large request: {tokens} tokens")
    except:
        pass
PYTHON
```

## API Access via REST (Advanced)

Modern mitmweb uses WebSocket-based APIs that are not easily accessible via curl. For REST-like programmatic access, use:

1. **Flow saving** (recommended): `--save-stream-file` + `mitmdump`
2. **Flow export** (manual): Export from web UI, then analyze
3. **Custom addon**: Write a Python addon that exposes a REST API

## Troubleshooting

### Issue: "No such file" when running mitmdump

**Cause**: Flow file doesn't exist yet or wrong path

**Solution**:
```bash
# Check if file exists
ls -lh ~/claude-flows.mitm

# Verify flows are being saved
lsof | grep claude-flows.mitm
```

### Issue: Scripts show no output

**Cause**: No flows match the filter or script has errors

**Solution**:
```bash
# Check if flows were captured
mitmdump -r ~/claude-flows.mitm --flow-detail 0

# Test script with verbose output
mitmdump -r ~/claude-flows.mitm -s script.py --set termlog_verbosity=debug
```

### Issue: Permission denied when running scripts

**Cause**: Scripts not executable

**Solution**:
```bash
chmod +x ~/.claude/skills/cc-trace/scripts/*.sh
```

## Best Practices

1. **Start with flow saving enabled** - Always use `--save-stream-file` for hybrid mode
2. **Use bundled scripts first** - Leverage pre-built analysis scripts before writing custom ones
3. **Filter early** - Use `--set flow_filter='~d api.anthropic.com'` to reduce noise
4. **Back up important captures** - Flow files can be large; compress or archive when done
5. **Clean up sensitive data** - Delete flow files containing API keys when analysis is complete

## Security Considerations

- Flow files contain **complete API requests** including API keys and sensitive data
- Store flow files securely (not in git repositories or public locations)
- Delete flow files after analysis is complete
- Never share flow files without sanitizing sensitive information

## Summary

**For interactive exploration**: Use mitmweb web UI only
**For automated analysis**: Use mitmdump or mitmweb with `--save-stream-file`
**For both**: Start mitmweb with `--save-stream-file ~/claude-flows.mitm`

The hybrid mode enables:
- ✅ Visual inspection in browser
- ✅ Automated analysis with Python scripts
- ✅ Real-time monitoring and alerting
- ✅ Batch processing of captured traffic
