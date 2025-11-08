#!/usr/bin/env bash
# Setup verification script for cc-trace skill
# Verifies mitmproxy installation, certificate trust, and proxy configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 CC-Trace Setup Verification"
echo "================================"
echo ""

# Track overall status
ALL_CHECKS_PASSED=true

# Check 1: mitmproxy installation
echo "📦 Checking mitmproxy installation..."
if command -v mitmproxy &> /dev/null; then
    MITM_VERSION=$(mitmproxy --version 2>&1 | head -n 1)
    echo -e "${GREEN}✓${NC} mitmproxy is installed: $MITM_VERSION"
else
    echo -e "${RED}✗${NC} mitmproxy is not installed"
    echo "   Install with: brew install mitmproxy"
    ALL_CHECKS_PASSED=false
fi
echo ""

# Check 2: mitmproxy certificate exists
echo "🔐 Checking mitmproxy certificate..."
CERT_PATH="$HOME/.mitmproxy/mitmproxy-ca-cert.pem"
if [ -f "$CERT_PATH" ]; then
    echo -e "${GREEN}✓${NC} Certificate exists at: $CERT_PATH"

    # Check certificate trust on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if security find-certificate -c mitmproxy -a 2>/dev/null | grep -q "mitmproxy"; then
            echo -e "${GREEN}✓${NC} Certificate is installed in keychain"

            # Check if trusted for SSL
            if security find-certificate -c mitmproxy -p 2>/dev/null | openssl x509 -noout -text 2>/dev/null | grep -q "Certificate"; then
                echo -e "${GREEN}✓${NC} Certificate appears to be trusted"
            else
                echo -e "${YELLOW}⚠${NC}  Could not verify certificate trust - may need manual verification"
            fi
        else
            echo -e "${RED}✗${NC} Certificate is NOT installed in keychain"
            echo "   Install with: sudo security add-trusted-cert -d -p ssl -p basic -k /Library/Keychains/System.keychain $CERT_PATH"
            ALL_CHECKS_PASSED=false
        fi
    fi
else
    echo -e "${RED}✗${NC} Certificate not found at: $CERT_PATH"
    echo "   Generate by running: mitmproxy (then quit with 'q')"
    ALL_CHECKS_PASSED=false
fi
echo ""

# Check 3: Shell function existence
echo "⚙️  Checking proxy_claude function..."
if type proxy_claude &> /dev/null; then
    echo -e "${GREEN}✓${NC} proxy_claude function is defined"
else
    echo -e "${RED}✗${NC} proxy_claude function is not defined"
    echo "   Add function to ~/.zshrc or ~/.bashrc (see setup-shell-configuration.md)"
    ALL_CHECKS_PASSED=false
fi
echo ""

# Check 4: Current proxy environment (if any)
echo "🌐 Checking current proxy environment..."
if [ -n "$HTTP_PROXY" ] || [ -n "$HTTPS_PROXY" ]; then
    echo -e "${YELLOW}⚠${NC}  Proxy environment variables are currently set:"
    [ -n "$HTTP_PROXY" ] && echo "   HTTP_PROXY=$HTTP_PROXY"
    [ -n "$HTTPS_PROXY" ] && echo "   HTTPS_PROXY=$HTTPS_PROXY"
    [ -n "$NODE_EXTRA_CA_CERTS" ] && echo "   NODE_EXTRA_CA_CERTS=$NODE_EXTRA_CA_CERTS"
    echo ""
    echo "   If mitmproxy is running, this is correct."
    echo "   If not, you may want to unset these variables."
else
    echo -e "${GREEN}✓${NC} No proxy environment variables currently set"
    echo "   This is normal when not running mitmproxy"
fi
echo ""

# Check 5: mitmproxy ports availability
echo "🔌 Checking port availability..."
if lsof -i :8080 &> /dev/null; then
    PORT_8080_PROCESS=$(lsof -i :8080 | tail -n 1 | awk '{print $1}')
    echo -e "${YELLOW}⚠${NC}  Port 8080 is in use by: $PORT_8080_PROCESS"
    echo "   This is expected if mitmproxy is running"
else
    echo -e "${GREEN}✓${NC} Port 8080 is available"
fi

if lsof -i :8081 &> /dev/null; then
    PORT_8081_PROCESS=$(lsof -i :8081 | tail -n 1 | awk '{print $1}')
    echo -e "${YELLOW}⚠${NC}  Port 8081 is in use by: $PORT_8081_PROCESS"
    echo "   This is expected if mitmweb is running"
else
    echo -e "${GREEN}✓${NC} Port 8081 is available"
fi
echo ""

# Check 6: Node.js/npm for TypeScript parser (optional)
echo "📜 Checking TypeScript parser dependencies (optional)..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓${NC} Node.js is installed: $NODE_VERSION"

    if command -v npx &> /dev/null; then
        echo -e "${GREEN}✓${NC} npx is available (can run TypeScript parser with 'npx tsx')"
    else
        echo -e "${YELLOW}⚠${NC}  npx not found (install npm to use TypeScript parser)"
    fi
else
    echo -e "${YELLOW}⚠${NC}  Node.js not installed (optional - only needed for parse-streamed-response.ts)"
    echo "   Install with: brew install node"
fi
echo ""

# Final summary
echo "================================"
if [ "$ALL_CHECKS_PASSED" = true ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    echo ""
    echo "You're ready to use cc-trace:"
    echo "  1. Start mitmweb: mitmweb --web-port 8081"
    echo "  2. Start Claude Code: proxy_claude"
    echo "  3. View traffic: http://127.0.0.1:8081"
else
    echo -e "${RED}✗ Some checks failed${NC}"
    echo ""
    echo "Please fix the issues above before using cc-trace."
    echo "See SKILL.md for detailed setup instructions."
fi
echo ""
