# Shell Configuration

This guide covers setting up the `proxy_claude` function to easily run Claude Code through mitmproxy.

**[← Previous: Installation & Certificate Setup](setup-installation-certificate.md)** | **[Next: Web Interface Guide →](usage-web-interface.md)**

---

## Configure Shell for Claude Code Proxying

### Edit Your Shell Configuration

1. Open your shell config file

For zsh (default on modern macOS):

```bash
nano ~/.zshrc
```

For bash:

```bash
nano ~/.bashrc
```

2. Copy and paste this at the end of the file:

```bash
proxy_claude() {
    # Set proxy environment variables
    export HTTP_PROXY=http://127.0.0.1:8080
    export HTTPS_PROXY=http://127.0.0.1:8080
    export http_proxy=http://127.0.0.1:8080
    export https_proxy=http://127.0.0.1:8080

    # Point Node.js to mitmproxy's CA certificate for HTTPS
    export NODE_EXTRA_CA_CERTS="$HOME/.mitmproxy/mitmproxy-ca-cert.pem"

    # Disable SSL verification warnings (optional, use with caution)
    export NODE_TLS_REJECT_UNAUTHORIZED=0

    echo "🔍 Proxy configured for mitmproxy (http://127.0.0.1:8080)"
    echo "📜 Using CA cert: $NODE_EXTRA_CA_CERTS"
    echo "🚀 Starting Claude Code..."

    # Launch Claude Code
    claude
}
```

3. Save the file (press `Ctrl+O`, then `Enter`, then `Ctrl+X`)

4. Reload your shell configuration

```bash
# For zsh
source ~/.zshrc

# For bash
source ~/.bashrc
```

5. Verify the function exists

```bash
type proxy_claude
```

You should see the function definition printed.

---

## Verification Checklist

- [ ] `proxy_claude` function exists (`type proxy_claude` works)
- [ ] Function is saved in shell configuration file

---

## Troubleshooting

### Claude Code doesn't respect proxy settings

**Solutions:**

1. Ensure you're using `proxy_claude` function, not just `claude`

2. Verify in the proxy_claude terminal:

```bash
env | grep -i proxy
```

Should show `HTTP_PROXY`, `HTTPS_PROXY`, etc.

3. Try setting additional proxy variables:

```bash
export ALL_PROXY=http://127.0.0.1:8080
export no_proxy="localhost,127.0.0.1"
```

### No traffic appears in mitmweb

If you complete this setup and later find no traffic is being captured:

1. Check environment variables in Claude Code terminal:

```bash
echo $HTTP_PROXY
echo $HTTPS_PROXY
echo $NODE_EXTRA_CA_CERTS
```

All should be set correctly.

2. Test the proxy with curl:

```bash
curl -x http://127.0.0.1:8080 http://example.com
```

This should appear in mitmweb when it's running.

### Function not found after restart

If `proxy_claude` is not available after restarting your terminal:

1. Verify you edited the correct shell config file:

```bash
# Check which shell you're using
echo $SHELL

# For zsh, should be in ~/.zshrc
# For bash, should be in ~/.bashrc
```

2. Make sure the function was saved properly:

```bash
# For zsh
grep -A 20 "proxy_claude()" ~/.zshrc

# For bash
grep -A 20 "proxy_claude()" ~/.bashrc
```

---

## Custom Port Configuration

If you need to use different ports (e.g., port 8080 is already in use), modify the function:

```bash
proxy_claude() {
    # Use custom ports (example: 9090 for proxy, 9091 for web)
    export HTTP_PROXY=http://127.0.0.1:9090
    export HTTPS_PROXY=http://127.0.0.1:9090
    export http_proxy=http://127.0.0.1:9090
    export https_proxy=http://127.0.0.1:9090

    export NODE_EXTRA_CA_CERTS="$HOME/.mitmproxy/mitmproxy-ca-cert.pem"
    export NODE_TLS_REJECT_UNAUTHORIZED=0

    echo "🔍 Proxy configured for mitmproxy (http://127.0.0.1:9090)"
    echo "📜 Using CA cert: $NODE_EXTRA_CA_CERTS"
    echo "🚀 Starting Claude Code..."

    claude
}
```

Then start mitmweb with: `mitmweb --listen-port 9090 --web-port 9091`

---

**[← Previous: Installation & Certificate Setup](setup-installation-certificate.md)** | **[Next: Web Interface Guide →](usage-web-interface.md)**
