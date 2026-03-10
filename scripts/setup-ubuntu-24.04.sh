#!/bin/bash
# =============================================================================
# OPENCLAW-system - Ubuntu 24.04 LTS Setup Script
# =============================================================================
# Version: 1.0.0
# Date: 2026-03-09
# Usage: sudo ./setup-ubuntu-24.04.sh
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OPENCLAW_USER="${OPENCLAW_USER:-openclaw}"
SSH_PORT="${SSH_PORT:-2222}"
NODE_VERSION="${NODE_VERSION:-23.11.1}"
PNPM_VERSION="${PNPM_VERSION:-10.23.0}"

# Logging
log() { echo -e "${BLUE}[OPENCLAW]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

# =============================================================================
# PHASE 1: System Update
# =============================================================================
phase_1_update() {
    log "Phase 1: System Update"

    apt update -y
    apt upgrade -y
    apt dist-upgrade -y
    apt autoremove -y
    apt autoclean

    log_success "System updated"
}

# =============================================================================
# PHASE 2: Create User
# =============================================================================
phase_2_user() {
    log "Phase 2: Create User ($OPENCLAW_USER)"

    if id "$OPENCLAW_USER" &>/dev/null; then
        log_warning "User $OPENCLAW_USER already exists"
    else
        useradd -m -s /bin/bash "$OPENCLAW_USER"
        log "Enter password for $OPENCLAW_USER:"
        passwd "$OPENCLAW_USER"
    fi

    usermod -aG sudo,docker "$OPENCLAW_USER"
    chmod 750 "/home/$OPENCLAW_USER"

    log_success "User configured"
}

# =============================================================================
# PHASE 3: SSH Hardening
# =============================================================================
phase_3_ssh() {
    log "Phase 3: SSH Hardening"

    # Backup original config
    cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.backup.$(date +%Y%m%d)"

    # Create new config
    cat > /etc/ssh/sshd_config << 'EOF'
# OPENCLAW Hardened SSH Configuration
Port SSH_PORT_PLACEHOLDER
AddressFamily inet
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
AllowUsers OPENCLAW_USER_PLACEHOLDER
MaxAuthTries 3
LoginGraceTime 60
X11Forwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

    # Replace placeholders
    sed -i "s/SSH_PORT_PLACEHOLDER/$SSH_PORT/g" /etc/ssh/sshd_config
    sed -i "s/OPENCLAW_USER_PLACEHOLDER/$OPENCLAW_USER/g" /etc/ssh/sshd_config

    # Verify syntax
    if sshd -t; then
        systemctl restart sshd
        log_success "SSH hardened (Port: $SSH_PORT)"
    else
        log_error "SSH config syntax error"
        exit 1
    fi
}

# =============================================================================
# PHASE 4: Firewall
# =============================================================================
phase_4_firewall() {
    log "Phase 4: Firewall (UFW)"

    ufw default deny incoming
    ufw default allow outgoing
    ufw allow "$SSH_PORT/tcp" comment 'SSH'
    ufw --force enable

    log_success "Firewall configured"
}

# =============================================================================
# PHASE 5: Fail2Ban
# =============================================================================
phase_5_fail2ban() {
    log "Phase 5: Fail2Ban"

    apt install -y fail2ban

    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3
ignoreip = 127.0.0.1/8

[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 24h
EOF

    systemctl enable fail2ban
    systemctl restart fail2ban

    log_success "Fail2Ban configured"
}

# =============================================================================
# PHASE 6: Docker
# =============================================================================
phase_6_docker() {
    log "Phase 6: Docker CE"

    apt install -y ca-certificates curl gnupg lsb-release

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list

    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl enable docker
    systemctl start docker

    # Add user to docker group
    usermod -aG docker "$OPENCLAW_USER"

    log_success "Docker installed"
}

# =============================================================================
# PHASE 7: Node.js & pnpm
# =============================================================================
phase_7_nodejs() {
    log "Phase 7: Node.js & pnpm"

    apt install -y curl

    # Install nvm for the user
    su - "$OPENCLAW_USER" -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash"

    # Install Node.js
    su - "$OPENCLAW_USER" -c 'source ~/.bashrc && nvm install v23.11.1 && nvm alias default v23.11.1'

    # Install pnpm
    su - "$OPENCLAW_USER" -c 'source ~/.bashrc && npm install -g pnpm@10.23.0 && pnpm setup'

    log_success "Node.js & pnpm installed"
}

# =============================================================================
# PHASE 8: Ollama
# =============================================================================
phase_8_ollama() {
    log "Phase 8: Ollama"

    curl -fsSL https://ollama.com/install.sh | sh

    # Configure for localhost only
    mkdir -p /etc/systemd/system/ollama.service.d
    cat > /etc/systemd/system/ollama.service.d/override.conf << 'EOF'
[Service]
Environment="OLLAMA_HOST=127.0.0.1:11434"
EOF

    systemctl daemon-reload
    systemctl restart ollama

    log_success "Ollama installed"
}

# =============================================================================
# PHASE 9: Tools
# =============================================================================
phase_9_tools() {
    log "Phase 9: Additional Tools"

    apt install -y git curl wget htop tree jq

    # Install gitleaks for security
    curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz | tar -xz -C /usr/local/bin gitleaks

    log_success "Tools installed"
}

# =============================================================================
# PHASE 10: Directory Structure
# =============================================================================
phase_10_structure() {
    log "Phase 10: Directory Structure"

    su - "$OPENCLAW_USER" -c "mkdir -p ~/projects ~/.openclaw/{config,data,logs,plugins,tmp}"
    su - "$OPENCLAW_USER" -c "mkdir -p ~/.openclaw/config/gears ~/.openclaw/data/{memory,knowledge}"
    su - "$OPENCLAW_USER" -c "chmod -R 750 ~/.openclaw"

    log_success "Directory structure created"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    clear
    echo "============================================================"
    echo "  OPENCLAW-system Ubuntu 24.04 LTS Setup"
    echo "============================================================"
    echo ""
    echo "Configuration:"
    echo "  - User: $OPENCLAW_USER"
    echo "  - SSH Port: $SSH_PORT"
    echo "  - Node.js: $NODE_VERSION"
    echo "  - pnpm: $PNPM_VERSION"
    echo ""

    read -p "Continue with installation? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi

    phase_1_update
    phase_2_user
    phase_3_ssh
    phase_4_firewall
    phase_5_fail2ban
    phase_6_docker
    phase_7_nodejs
    phase_8_ollama
    phase_9_tools
    phase_10_structure

    echo ""
    echo "============================================================"
    echo "  Installation Complete!"
    echo "============================================================"
    echo ""
    echo "IMPORTANT: Next steps:"
    echo "1. Add your SSH key: ssh-copy-id -p $SSH_PORT $OPENCLAW_USER@YOUR_IP"
    echo "2. Test login: ssh -p $SSH_PORT $OPENCLAW_USER@YOUR_IP"
    echo "3. Pull model: ollama pull llama3.2:3b"
    echo "4. Clone OpenClaw and configure"
    echo ""
    echo "Firewall status:"
    ufw status
}

main "$@"
