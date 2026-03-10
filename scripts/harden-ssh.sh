#!/bin/bash
# =============================================================================
# OPENCLAW-system - SSH Hardening Script
# =============================================================================
# Version: 1.0.0
# Date: 2026-03-09
# Usage: sudo ./harden-ssh.sh [port]
# =============================================================================

set -euo pipefail

# Configuration
SSH_PORT="${1:-2222}"
SSH_USER="${SUDO_USER:-$USER}"
SSHD_CONFIG="/etc/ssh/sshd_config"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[SSH]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

# Check root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root"
    exit 1
fi

# Check if SSH key exists for user
check_ssh_key() {
    local ssh_dir="/home/$SSH_USER/.ssh"

    if [[ ! -d "$ssh_dir" ]]; then
        warn "No .ssh directory found for $SSH_USER"
        warn "Generate a key on your local machine:"
        warn "  ssh-keygen -t ed25519 -C '$SSH_USER@openclaw-vps'"
        warn "Then copy it:"
        warn "  ssh-copy-id -i ~/.ssh/id_ed25519.pub $SSH_USER@YOUR_IP"
        echo ""
        read -p "Press Enter after you've added your SSH key..."
    fi
}

# Backup current config
backup_config() {
    local backup_file="${SSHD_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$SSHD_CONFIG" "$backup_file"
    log "Backup saved to: $backup_file"
}

# Generate hardened config
generate_config() {
    log "Generating hardened SSH configuration..."

    cat > "$SSHD_CONFIG" << EOF
# =============================================================================
# OPENCLAW Hardened SSH Configuration
# Generated: $(date)
# =============================================================================

# Network
Port $SSH_PORT
AddressFamily inet
ListenAddress 0.0.0.0

# Authentication - CRITICAL SETTINGS
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
MaxAuthTries 3
MaxSessions 5

# Allowed users
AllowUsers $SSH_USER

# Cryptography (Modern, Secure)
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
HostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256

# Host keys
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key

# Timeouts
LoginGraceTime 60
ClientAliveInterval 300
ClientAliveCountMax 2

# Disable unnecessary features
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
PermitTunnel no
PermitUserEnvironment no
DisableForwarding yes

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Other
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
PrintMotd no
AcceptEnv LANG LC_*

# SFTP
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

    log "Configuration generated"
}

# Verify config
verify_config() {
    log "Verifying configuration..."
    if sshd -t; then
        log "Configuration syntax OK"
    else
        error "Configuration syntax error!"
        exit 1
    fi
}

# Restart SSH
restart_ssh() {
    log "Restarting SSH service..."
    systemctl restart sshd
    systemctl status sshd --no-pager
}

# Update firewall
update_firewall() {
    if command -v ufw &>/dev/null; then
        log "Updating firewall..."
        # Remove old SSH rule if on port 22
        ufw delete allow 22/tcp 2>/dev/null || true
        # Add new rule
        ufw allow "$SSH_PORT/tcp" comment 'SSH'
        log "Firewall updated for port $SSH_PORT"
    fi
}

# Update Fail2Ban
update_fail2ban() {
    if command -v fail2ban-client &>/dev/null; then
        log "Updating Fail2Ban configuration..."

        if [[ -f /etc/fail2ban/jail.local ]]; then
            sed -i "s/port = .*/port = $SSH_PORT/" /etc/fail2ban/jail.local 2>/dev/null || true
        fi

        systemctl restart fail2ban
        log "Fail2Ban updated"
    fi
}

# Final verification
final_check() {
    echo ""
    echo "============================================================"
    echo "  SSH Hardening Complete"
    echo "============================================================"
    echo ""
    echo "Port: $SSH_PORT"
    echo "Allowed user: $SSH_USER"
    echo ""
    warn "IMPORTANT: Test before closing this session!"
    echo ""
    echo "In a NEW terminal, run:"
    echo "  ssh -p $SSH_PORT $SSH_USER@YOUR_IP"
    echo ""
    echo "If connection fails, you can restore the backup:"
    echo "  cp ${SSHD_CONFIG}.backup.* $SSHD_CONFIG"
    echo "  systemctl restart sshd"
    echo ""
}

# Main
main() {
    echo "============================================================"
    echo "  OPENCLAW SSH Hardening Script"
    echo "============================================================"
    echo ""
    echo "Port: $SSH_PORT"
    echo "User: $SSH_USER"
    echo ""

    check_ssh_key
    backup_config
    generate_config
    verify_config
    update_firewall
    update_fail2ban
    restart_ssh
    final_check
}

main "$@"
