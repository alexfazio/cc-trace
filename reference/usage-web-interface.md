# Web Interface Guide

This guide covers using mitmweb to capture and inspect Claude Code's API traffic.

**[← Previous: Shell Configuration](setup-shell-configuration.md)** | **[Next: CLI Interface Guide →](usage-cli-interface.md)**

---

## Start mitmweb (Web Interface)

1. Open a new terminal window
2. Start mitmweb

```bash
mitmweb --web-port 8081
```

Options explained:
- `--web-port 8081`: Web interface port (default is 8081)
- Proxy listens on port 8080 by default

Optional flags:

```bash
# Don't automatically open browser
mitmweb --web-port 8081 --no-web-open-browser

# Bind to all interfaces (useful for remote access)
mitmweb --web-host 0.0.0.0 --web-port 8081

# Set a specific listen port for the proxy
mitmweb --listen-port 8080 --web-port 8081
```

3. Access the web interface
   - Automatically opens in your browser, or
   - Manually navigate to: http://127.0.0.1:8081
4. You should see the mitmweb interface with a clean, modern web UI (initially empty with no flows captured yet)

### Troubleshooting: mitmweb won't start / Port already in use

**Error:** `OSError: [Errno 48] Address already in use`

**Solutions:**

1. Check what's using the port:

```bash
lsof -i :8080
lsof -i :8081
```

2. Kill the process:

```bash
kill -9 <PID>
```

3. Or use different ports:

```bash
mitmweb --listen-port 8888 --web-port 8889
```

Remember to update your `proxy_claude` function to use port 8888.

---

## Start Claude Code with Proxy

1. Open a new terminal window (keep mitmweb running in the first)
2. Run Claude Code through the proxy

```bash
proxy_claude
```

3. You should see:

```
🔍 Proxy configured for mitmproxy (http://127.0.0.1:8080)
📜 Using CA cert: /Users/yourname/.mitmproxy/mitmproxy-ca-cert.pem
🚀 Starting Claude Code...
```

Claude Code starts normally

---

## Verify Traffic Capture

1. Ask Claude Code a question
   - Type any prompt in Claude Code
   - Wait for a response

2. Check mitmweb interface
   - Switch to your browser with mitmweb
   - You should see requests to api.anthropic.com
   - Each request appears as a row in the flow list

3. If no traffic appears, see Troubleshooting section below

### Troubleshooting: No traffic appears in mitmweb

**Solutions:**

1. Verify mitmweb is running:

```bash
# Check if proxy port is listening
lsof -i :8080
```

2. Check environment variables in Claude Code terminal:

```bash
echo $HTTP_PROXY
echo $HTTPS_PROXY
echo $NODE_EXTRA_CA_CERTS
```

All should be set correctly.

3. Test the proxy with curl:

```bash
curl -x http://127.0.0.1:8080 http://example.com
```

This should appear in mitmweb.

4. Ensure you're using `proxy_claude` function:

```bash
# Verify environment in the Claude terminal
env | grep -i proxy
```

---

## Inspect API Requests and Responses

### Understanding the mitmweb Interface

**Main View:**
- Flow List (left): All captured HTTP requests
- Flow Detail (right): Selected request/response details

### Inspecting a Request

1. Click on any api.anthropic.com request
2. View Request Details
   - Click Request tab
   - See: Headers (Authentication, content-type, etc.), Content (the actual JSON payload sent to Claude), Query (URL parameters if any)
3. View Response Details
   - Click Response tab
   - See: Status (HTTP status code), Headers (Response metadata), Content (Claude's response, may be streamed)
4. Inspect the JSON payload
   - Look for: `system` (System prompts), `messages` (Conversation history), `tools` (Available tool definitions), `model` (Which Claude model is being used), `max_tokens` (Token limits)

### Filtering Requests

1. Use the filter bar at the top of flow list

Common filters:

```
# Show only Anthropic API requests
~d api.anthropic.com

# Show only POST requests
~m POST

# Show requests with "messages" in URL
~u messages

# Combine filters
~d api.anthropic.com & ~m POST
```

Type directly in the filter box and press Enter to apply.

### Useful Features

- **Search:** `Cmd+F` to search within requests/responses
- **Export:** Right-click → Export for saving flows
- **Clear:** Click the trash icon to clear all flows
- **Replay:** Right-click → Replay to resend a request

---

## Quick Reference: Common mitmweb Commands

```bash
# Start mitmweb (web interface)
mitmweb --web-port 8081

# Start with filtering
mitmweb --set flow_filter='~d api.anthropic.com'

# Start without opening browser
mitmweb --no-web-open-browser

# Start on custom ports
mitmweb --listen-port 9090 --web-port 9091

# Start with a script
mitmweb -s my_script.py

# Replay saved flows
mitmweb -r saved-flows.mitm
```

---

**[← Previous: Shell Configuration](setup-shell-configuration.md)** | **[Next: CLI Interface Guide →](usage-cli-interface.md)**
