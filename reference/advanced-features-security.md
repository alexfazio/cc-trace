# Advanced Features & Security

This guide covers advanced mitmproxy features and important security considerations.

**[← Previous: Daily Workflow & Tips](workflow-daily-tips.md)** | **[Back to Overview](SKILL.md)**

---

## Advanced Features

### Save Flows for Later Analysis

#### Export from Web Interface

1. Export all flows
   - In mitmweb, click the ≡ menu
   - Select File → Export
   - Choose format (mitmproxy, HAR, etc.)

2. Export specific flows
   - Right-click on a flow
   - Select Export
   - Save to file

#### Replay Flows

```bash
# Replay with mitmproxy CLI
mitmproxy -r saved-flows.mitm

# Replay with mitmweb
mitmweb -r saved-flows.mitm

# Replay with mitmdump
mitmdump -r saved-flows.mitm
```

---

### Python Scripting

Create custom scripts to modify traffic on-the-fly.

#### Example: Log Requests

Create `~/claude-analysis/log_requests.py`:

```python
def request(flow):
    if "api.anthropic.com" in flow.request.pretty_url:
        print(f"→ {flow.request.method} {flow.request.path}")

def response(flow):
    if "api.anthropic.com" in flow.request.pretty_url:
        print(f"← {flow.response.status_code}")
```

Run with:

```bash
mitmweb -s ~/claude-analysis/log_requests.py
```

#### Example: Extract Token Usage

Create `~/claude-analysis/extract_tokens.py`:

```python
import json

def response(flow):
    if "api.anthropic.com" in flow.request.pretty_url:
        try:
            # Parse response body
            content = flow.response.text
            if "usage" in content:
                data = json.loads(content)
                if "usage" in data:
                    usage = data["usage"]
                    print(f"Tokens - Input: {usage.get('input_tokens', 0)}, Output: {usage.get('output_tokens', 0)}")
        except:
            pass
```

#### Example: Modify Requests

```python
def request(flow):
    if "api.anthropic.com" in flow.request.pretty_url:
        # Example: Add custom headers
        flow.request.headers["X-Custom-Header"] = "value"

        # Example: Modify request body
        try:
            data = json.loads(flow.request.text)
            # Modify data as needed
            flow.request.text = json.dumps(data)
        except:
            pass
```

**Note:** Be careful when modifying requests - this can break functionality!

---

### Filter Specific API Endpoints

#### Using Command-Line Filters

```bash
# Only show /messages endpoint
mitmweb --set flow_filter='~d api.anthropic.com & ~u /messages'

# Show only successful responses
mitmweb --set flow_filter='~c 200'

# Show only large responses (>10000 bytes)
mitmweb --set flow_filter='~bs 10000'
```

#### Filter Syntax Reference

```
~d domain     # Domain filter
~u url        # URL filter
~m method     # Method (GET, POST, etc.)
~c code       # Status code
~bs size      # Response body size
~bq size      # Request body size
~h header     # Header filter
~t "text"     # Body text search
&             # AND operator
|             # OR operator
!             # NOT operator
```

---

## Security Notes

### Important Security Considerations

**Local use only:** The proxy setup in this guide is for local debugging only

**Certificate trust:** You're trusting mitmproxy to intercept HTTPS traffic
- This gives mitmproxy access to decrypt all HTTPS traffic
- Only install the certificate on machines you control
- Remove it when you're done debugging

**Sensitive data:** Be careful with API keys and tokens in captured traffic
- Captured traffic contains your API keys
- Don't share raw exports without redacting sensitive data
- Store captured flows securely

**Production warning:** Never use this setup in production environments
- The `NODE_TLS_REJECT_UNAUTHORIZED=0` setting disables security
- Only use for local development and debugging

### Clean Up After Debugging

#### Remove the Certificate

When you're done debugging, remove the certificate:

```bash
sudo security delete-certificate -c mitmproxy /Library/Keychains/System.keychain
```

Verify removal:

```bash
security find-certificate -c mitmproxy -a
```

Should return no results.

#### Clear Proxy Settings

Clear environment variables when not debugging:

```bash
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NODE_EXTRA_CA_CERTS NODE_TLS_REJECT_UNAUTHORIZED
```

Add this to a function for easy cleanup:

```bash
# Add to ~/.zshrc or ~/.bashrc
unproxy() {
    unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NODE_EXTRA_CA_CERTS NODE_TLS_REJECT_UNAUTHORIZED
    echo "🚫 Proxy environment variables cleared"
}
```

#### Delete Saved Flows

If you've saved flows with sensitive data:

```bash
# Find and remove flow files
find ~/claude-analysis -name "*.mitm" -delete
find ~/claude-analysis -name "*.har" -delete
```

---

## Quick Reference: Common Commands

### Starting mitmproxy

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

# Start mitmproxy (CLI)
mitmproxy

# Start mitmdump (headless, logging)
mitmdump -w output.mitm

# Replay saved flows
mitmweb -r saved-flows.mitm
```

### Certificate Management

```bash
# Install certificate (macOS)
sudo security add-trusted-cert -d -p ssl -p basic \
  -k /Library/Keychains/System.keychain \
  ~/.mitmproxy/mitmproxy-ca-cert.pem

# Verify certificate is trusted
security find-certificate -c mitmproxy -a

# Remove certificate
sudo security delete-certificate -c mitmproxy /Library/Keychains/System.keychain
```

---

## Additional Resources

### Official Documentation
- Official Documentation: https://docs.mitmproxy.org/
- Installation Guide: https://docs.mitmproxy.org/stable/overview/installation/
- Certificate Setup: https://docs.mitmproxy.org/stable/concepts/certificates/
- mitmweb Tutorial: https://docs.mitmproxy.org/stable/mitmproxytutorial/userinterface/
- Scripting Guide: https://docs.mitmproxy.org/stable/addons-overview/

### Community & Support
- GitHub Repository: https://github.com/mitmproxy/mitmproxy
- Community Discord: https://discord.gg/mitmproxy

### Related Projects
- System Prompts Repo: https://github.com/gsabran/claude-code-system-prompts

---

## Conclusion

You're now equipped with everything you need to intercept, analyze, and understand Claude Code's API requests using mitmproxy! This free, open-source setup gives you deep insights into how AI coding assistants work under the hood.

Remember to:
- Use this only for debugging and learning
- Remove certificates when done
- Keep captured data secure
- Never use in production

Happy debugging!

---

**[← Previous: Daily Workflow & Tips](workflow-daily-tips.md)** | **[Back to Overview](SKILL.md)**
