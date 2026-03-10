#!/bin/bash
# =============================================================================
# OPENCLAW-system - Security Audit Script
# =============================================================================
# Version: 1.0.0
# Date: 2026-03-09
# Usage: ./security-audit.sh
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
AUDIT_FILE="security-audit-$(date +%Y%m%d-%H%M%S).txt"
PASS=0
FAIL=0
WARN=0

# Output functions
pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((PASS++)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; ((FAIL++)); }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; ((WARN++)); }
info() { echo "[INFO] $1"; }

# Header
echo "============================================================"
echo "  OPENCLAW Security Audit - $(date)"
echo "============================================================"
echo ""

# 1. SSH Configuration
echo "### 1. SSH Configuration ###"

if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
    pass "Root login disabled"
else
    fail "Root login NOT disabled"
fi

if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null; then
    pass "Password authentication disabled"
else
    fail "Password authentication enabled"
fi

SSH_PORT=$(grep "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "22")
if [[ "$SSH_PORT" != "22" ]]; then
    pass "SSH on non-standard port: $SSH_PORT"
else
    warn "SSH on default port 22"
fi

echo ""

# 2. Firewall
echo "### 2. Firewall ###"

if command -v ufw &>/dev/null; then
    UFW_STATUS=$(ufw status 2>/dev/null | head -1)
    if [[ "$UFW_STATUS" == *"active"* ]]; then
        pass "UFW firewall active"
    else
        fail "UFW firewall NOT active"
    fi
else
    warn "UFW not installed"
fi

echo ""

# 3. Fail2Ban
echo "### 3. Fail2Ban ###"

if systemctl is-active --quiet fail2ban 2>/dev/null; then
    pass "Fail2Ban active"
    BANNED=$(fail2ban-client status sshd 2>/dev/null | grep "Banned" | awk '{print $2}' || echo "0")
    info "Banned IPs for SSH: $BANNED"
else
    warn "Fail2Ban not active"
fi

echo ""

# 4. Services Listening
echo "### 4. Services on External Interfaces ###"

EXTERNAL_PORTS=$(ss -tlnp 2>/dev/null | grep -v "127.0.0.1" | grep LISTEN || true)
if [[ -z "$EXTERNAL_PORTS" ]]; then
    pass "No services exposed on external interfaces"
else
    warn "Services exposed:"
    echo "$EXTERNAL_PORTS"
fi

echo ""

# 5. Ollama Security
echo "### 5. Ollama Security ###"

if ss -tlnp 2>/dev/null | grep -q "127.0.0.1:11434"; then
    pass "Ollama bound to localhost only"
elif ss -tlnp 2>/dev/null | grep -q "0.0.0.0:11434"; then
    fail "Ollama exposed on 0.0.0.0:11434"
else
    info "Ollama not running or not detected"
fi

echo ""

# 6. OpenClaw Gateway
echo "### 6. OpenClaw Gateway Security ###"

if ss -tlnp 2>/dev/null | grep -q "127.0.0.1:18789"; then
    pass "Gateway bound to localhost"
elif ss -tlnp 2>/dev/null | grep -q "0.0.0.0:18789"; then
    fail "Gateway exposed on 0.0.0.0"
else
    info "Gateway not running"
fi

echo ""

# 7. Docker Security
echo "### 7. Docker Security ###"

if command -v docker &>/dev/null; then
    DOCKER_VERSION=$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')
    info "Docker version: $DOCKER_VERSION"

    ROOTLESS=$(docker context ls 2>/dev/null | grep -c "rootless" || echo "0")
    if [[ "$ROOTLESS" -gt 0 ]]; then
        pass "Docker rootless mode detected"
    else
        warn "Docker not in rootless mode"
    fi
else
    info "Docker not installed"
fi

echo ""

# 8. User Permissions
echo "### 8. File Permissions ###"

if [[ -f ~/.openclaw/config/.env ]]; then
    ENV_PERMS=$(stat -c "%a" ~/.openclaw/config/.env 2>/dev/null || echo "unknown")
    if [[ "$ENV_PERMS" == "600" ]]; then
        pass ".env permissions correct (600)"
    else
        fail ".env permissions too open ($ENV_PERMS)"
    fi
else
    info ".env file not found"
fi

if [[ -f ~/.ssh/authorized_keys ]]; then
    AK_PERMS=$(stat -c "%a" ~/.ssh/authorized_keys 2>/dev/null || echo "unknown")
    if [[ "$AK_PERMS" == "600" ]]; then
        pass "authorized_keys permissions correct (600)"
    else
        fail "authorized_keys permissions too open ($AK_PERMS)"
    fi
fi

echo ""

# 9. PM2
echo "### 9. PM2 Security ###"

if command -v pm2 &>/dev/null; then
    PM2_VERSION=$(pm2 --version 2>/dev/null || echo "unknown")
    info "PM2 version: $PM2_VERSION"

    # Check if >= 5.4.3
    MAJOR=$(echo "$PM2_VERSION" | cut -d. -f1)
    MINOR=$(echo "$PM2_VERSION" | cut -d. -f2)
    PATCH=$(echo "$PM2_VERSION" | cut -d. -f3)

    if [[ "$MAJOR" -gt 5 ]] || \
       ([[ "$MAJOR" -eq 5 ]] && [[ "$MINOR" -gt 4 ]]) || \
       ([[ "$MAJOR" -eq 5 ]] && [[ "$MINOR" -eq 4 ]] && [[ "$PATCH" -ge 3 ]]); then
        pass "PM2 version secure (>= 5.4.3)"
    else
        fail "PM2 version vulnerable (< 5.4.3)"
    fi
else
    info "PM2 not installed"
fi

echo ""

# 10. System Updates
echo "### 10. System Updates ###"

UPDATES=$(apt list --upgradable 2>/dev/null | wc -l)
if [[ "$UPDATES" -le 1 ]]; then
    pass "System up to date"
else
    warn "$((UPDATES - 1)) packages pending update"
fi

echo ""

# Summary
echo "============================================================"
echo "  AUDIT SUMMARY"
echo "============================================================"
echo -e "  ${GREEN}PASSED:${NC} $PASS"
echo -e "  ${RED}FAILED:${NC} $FAIL"
echo -e "  ${YELLOW}WARNINGS:${NC} $WARN"
echo ""

if [[ $FAIL -gt 0 ]]; then
    echo -e "${RED}CRITICAL: There are security issues that need immediate attention${NC}"
    exit 1
elif [[ $WARN -gt 0 ]]; then
    echo -e "${YELLOW}WARNING: Review warnings and consider remediation${NC}"
    exit 0
else
    echo -e "${GREEN}OK: All security checks passed${NC}"
    exit 0
fi
