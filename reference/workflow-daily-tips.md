# Daily Workflow & Tips

This guide covers typical daily usage patterns and what insights you can gain from inspecting Claude Code's traffic.

**[← Previous: CLI Interface Guide](usage-cli-interface.md)** | **[Next: Advanced Features & Security →](advanced-features-security.md)**

---

## Daily Usage Workflow

Once set up, here's your typical workflow:

### Start Your Session

1. Terminal 1: Start mitmweb

```bash
mitmweb --web-port 8081
```

2. Terminal 2: Start Claude Code with proxy

```bash
proxy_claude
```

3. Browser: Open mitmweb at http://127.0.0.1:8081

### During Your Session

- Use Claude Code normally
- Monitor traffic in mitmweb
- Click on requests to inspect details
- Filter as needed with: `~d api.anthropic.com`

### End Your Session

1. Exit Claude Code (type `/exit` or close the session)
2. Stop mitmweb (press `Ctrl+C` in Terminal 1)
3. Optional: Clear proxy environment

```bash
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NODE_EXTRA_CA_CERTS
```

---

## Parse Streamed Responses (Optional)

Anthropic's API uses Server-Sent Events (SSE) streaming, which can be hard to read in raw format.

### Option A: Use the Web Interface

mitmweb shows streamed responses but they may appear as:

```
event: message_start
  data: {"type":"message_start"...}

event: content_block_delta
  data: {"type":"content_block_delta"...}
```

### Option B: Parse with a Python Script

1. Save the following script as `~/claude-analysis/parse-sse.py`:

```python
#!/usr/bin/env python3
import sys
import json

for line in sys.stdin:
    line = line.strip()
    if line.startswith('data: '):
        try:
            data = json.loads(line[6:])
            print(json.dumps(data, indent=2))
        except json.JSONDecodeError:
            pass
```

2. Make it executable

```bash
chmod +x ~/claude-analysis/parse-sse.py
```

3. Use it by copying the raw response from mitmweb and pasting into the terminal:

```bash
pbpaste | python3 ~/claude-analysis/parse-sse.py
```

### Option C: Use a TypeScript Parser

For more advanced parsing:
- Get the TypeScript parser from https://github.com/gsabran/claude-code-system-prompts
- Use `npx tsx` to run it

---

## What You Can Inspect

Once properly set up, you'll see:

### Request Details

- **System prompts:** Instructions given to Claude Code
- **User messages:** Your actual queries
- **Tool definitions:** Available tools (Read, Write, Bash, TodoWrite, Task, etc.)
- **Context:** File contents, git status, conversation history
- **Model parameters:**
  - `model`: e.g., "claude-sonnet-4-5-20250929"
  - `max_tokens`: Token limits
  - `temperature`: Randomness setting
  - `stream`: Whether using streaming responses

### Response Details

- **Model outputs:** Claude's text responses
- **Tool calls:** Which tools Claude uses and when
- **Tool parameters:** Arguments passed to each tool
- **Token usage:** Input/output token counts
- **Thinking blocks:** Claude's reasoning process (if available)
- **Stop reasons:** Why generation stopped

---

## Patterns You'll Discover

By inspecting traffic over time, you'll notice:

### Parallel Tool Calls
- Multiple tools called simultaneously
- Used when operations are independent

### Sequential Operations
- Tool dependencies (one result feeds into another)
- Used when operations must happen in order

### Context Window Management
- How Claude Code summarizes conversations
- When context is trimmed to fit token limits

### Task Delegation
- When sub-agents are spawned
- How tasks are isolated with separate context

### TODO System
- How tasks are tracked and completed
- When todos are created, updated, and marked complete

### Optimization Strategies
- Using cheaper models (Haiku) for simple tasks
- Delegating subtasks to isolate context
- Summarizing when approaching token limits

---

## Tips for Effective Analysis

### Focus on Specific Endpoints

```bash
# Only show /messages endpoint
mitmweb --set flow_filter='~d api.anthropic.com & ~u /messages'
```

### Look for Patterns

- Compare requests for similar tasks
- Note which tools are used together
- Observe how context grows over time

### Export Important Flows

- Right-click → Export to save interesting interactions
- Keep a library of examples for reference

### Compare Model Behavior

- Try the same task multiple times
- Note variations in tool usage
- Identify consistent patterns

---

**[← Previous: CLI Interface Guide](usage-cli-interface.md)** | **[Next: Advanced Features & Security →](advanced-features-security.md)**
