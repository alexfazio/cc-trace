# Installation & Certificate Setup

This guide covers installing mitmproxy, generating certificates, and installing them on your system.

**[← Back to Overview](SKILL.md)** | **[Next: Shell Configuration →](setup-shell-configuration.md)**

---

## Step 1: Install mitmproxy

### Option A: Using Homebrew (Recommended for macOS)

1. Install via Homebrew

```bash
brew install --cask mitmproxy
```

2. Verify installation

```bash
mitmproxy --version
```

You should see version information for mitmproxy, mitmweb, and mitmdump.

### Option B: Download Standalone Binaries

1. Visit https://mitmproxy.org/
2. Download the appropriate package for your OS
3. Extract and add to your PATH

### Troubleshooting: "Command not found: mitmproxy"

If you get this error after installation:

1. Verify Homebrew installation:

```bash
brew list | grep mitmproxy
```

2. Reinstall if needed:

```bash
brew reinstall mitmproxy
```

3. Check PATH:

```bash
which mitmweb
```

---

## Step 2: Start mitmproxy and Generate Certificates

1. Start mitmproxy for the first time (this generates the CA certificate in `~/.mitmproxy/`):

```bash
mitmproxy
```

2. Verify certificate generation

```bash
ls ~/.mitmproxy/
```

You should see files like:
- mitmproxy-ca-cert.pem
- mitmproxy-ca-cert.p12
- mitmproxy-ca.pem
- And others

3. Exit mitmproxy (press `q` then `y` to quit)

---

## Step 3: Install mitmproxy CA Certificate on macOS

To intercept HTTPS traffic, you need to trust mitmproxy's Certificate Authority.

### Method A: Automatic Installation (Easiest)

1. Start mitmweb

```bash
mitmweb
```

2. Configure your browser to use the proxy temporarily
   - Set HTTP/HTTPS proxy to localhost:8080
   - Or use browser extensions like FoxyProxy

3. Visit the magic URL
   - Navigate to http://mitm.it
   - Click on the Apple icon
   - Download and install the certificate
   - Follow macOS prompts to trust it

4. Quit mitmweb (press `Ctrl+C` in the terminal)

### Method B: Command Line Installation (Recommended)

This method directly installs the certificate to the system keychain:

```bash
sudo security add-trusted-cert -d -p ssl -p basic -k /Library/Keychains/System.keychain ~/.mitmproxy/mitmproxy-ca-cert.pem
```

Enter your macOS password when prompted.

### Verify Certificate Installation

1. Open Keychain Access (`Cmd+Space`, type "Keychain Access")
2. Select System keychain
3. Search for "mitmproxy"
4. You should see "mitmproxy" certificate marked as trusted

---

## Verification Checklist

Use this to ensure everything is working:

- [ ] mitmproxy is installed (`mitmproxy --version` works)
- [ ] Certificate generated in `~/.mitmproxy/`
- [ ] CA certificate installed and trusted in macOS Keychain

---

## Troubleshooting

### SSL/Certificate Errors

**Error:** `UNABLE_TO_VERIFY_LEAF_SIGNATURE` or similar

**Solutions:**

1. Verify certificate path is correct:

```bash
ls -la ~/.mitmproxy/mitmproxy-ca-cert.pem
```

2. Check certificate is trusted:

```bash
security find-certificate -c mitmproxy -a
```

3. Re-install the certificate:

```bash
sudo security add-trusted-cert -d -p ssl -p basic -k /Library/Keychains/System.keychain ~/.mitmproxy/mitmproxy-ca-cert.pem
```

4. Check the certificate file exists and is readable:

```bash
cat ~/.mitmproxy/mitmproxy-ca-cert.pem | head -n 3
```

Should show `-----BEGIN CERTIFICATE-----`

### Proxy works but HTTPS content is encrypted/unreadable

**Solutions:**

1. Verify NODE_EXTRA_CA_CERTS will be set (we'll configure this in the next guide)

2. Test certificate manually:

```bash
NODE_EXTRA_CA_CERTS=~/.mitmproxy/mitmproxy-ca-cert.pem curl -x http://127.0.0.1:8080 https://api.anthropic.com
```

---

**[← Back to Overview](SKILL.md)** | **[Next: Shell Configuration →](setup-shell-configuration.md)**
