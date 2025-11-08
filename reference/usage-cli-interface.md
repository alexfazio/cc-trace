# CLI Interface Guide (Optional/Advanced)

This guide covers using mitmproxy's terminal interface instead of the web interface.

**[← Previous: Web Interface Guide](usage-web-interface.md)** | **[Next: Daily Workflow & Tips →](workflow-daily-tips.md)**

---

## Using mitmproxy CLI

If you prefer a terminal interface instead of web:

### Start mitmproxy

1. Start mitmproxy (CLI version)

```bash
mitmproxy
```

2. The terminal interface will appear with a list view of captured flows

### Basic Keyboard Shortcuts

- `↑`/`↓`: Navigate flows
- `Enter`: View flow details
- `q`: Back/quit
- `f`: Filter
- `C`: Clear all flows
- `?`: Help

### Viewing Flow Details

1. Use arrow keys to select a flow
2. Press `Enter` to view details
3. Navigate tabs:
   - `Tab`: Cycle through Request/Response/Detail tabs
   - `e`: Edit the selected flow
   - `m`: Change view mode (hex, auto, etc.)
4. Press `q` to return to flow list

### Filtering Flows

1. Filter examples:
   - Press `f`
   - Type: `~d api.anthropic.com`
   - Press `Enter`

Common filter expressions:

```
# Show only Anthropic API requests
~d api.anthropic.com

# Show only POST requests
~m POST

# Show requests with "messages" in URL
~u messages

# Combine filters
~d api.anthropic.com & ~m POST

# Show only responses with status 200
~c 200

# Show requests larger than 1000 bytes
~bq 1000
```

2. Clear filter:
   - Press `f`
   - Clear the filter text
   - Press `Enter`

---

## Using mitmdump (Headless Mode)

For logging traffic without an interface:

### Basic Usage

```bash
# Log all traffic to a file
mitmdump -w output.mitm

# Filter while logging
mitmdump -w output.mitm --set flow_filter='~d api.anthropic.com'

# Print requests to console
mitmdump --flow-detail 2
```

### Replay Captured Flows

```bash
# Replay with mitmproxy CLI
mitmproxy -r saved-flows.mitm

# Replay with mitmweb
mitmweb -r saved-flows.mitm
```

---

## Quick Reference: CLI Commands

```bash
# Start mitmproxy (CLI)
mitmproxy

# Start with filtering
mitmproxy --set flow_filter='~d api.anthropic.com'

# Start mitmdump (headless, logging)
mitmdump -w output.mitm

# Replay saved flows
mitmproxy -r saved-flows.mitm
```

---

## When to Use CLI vs Web Interface

**Use Web Interface (mitmweb) when:**
- You want easy visual inspection
- You need to search/filter frequently
- You're analyzing complex request/response structures
- You prefer point-and-click navigation

**Use CLI (mitmproxy) when:**
- You prefer keyboard-driven workflows
- You're working on a remote server without GUI
- You want to minimize resource usage
- You're comfortable with terminal interfaces

**Use mitmdump when:**
- You need automated logging
- You're running scripts to process traffic
- You want minimal overhead
- You're integrating with other tools

---

**[← Previous: Web Interface Guide](usage-web-interface.md)** | **[Next: Daily Workflow & Tips →](workflow-daily-tips.md)**
