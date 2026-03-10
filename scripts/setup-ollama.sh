#!/bin/bash
# =============================================================================
# OPENCLAW-system - Ollama Setup Script
# =============================================================================
# Version: 1.0.0
# Date: 2026-03-09
# Usage: ./setup-ollama.sh
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[OLLAMA]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

# Default model
DEFAULT_MODEL="llama3.2:3b"

# Check if Ollama is installed
check_ollama() {
    if command -v ollama &>/dev/null; then
        success "Ollama installed: $(ollama --version)"
        return 0
    else
        error "Ollama not installed"
        return 1
    fi
}

# Ensure localhost binding
ensure_localhost() {
    log "Checking localhost binding..."

    CURRENT_BIND=$(ss -tlnp 2>/dev/null | grep 11434 | awk '{print $4}' | cut -d: -f1)

    if [[ "$CURRENT_BIND" == "127.0.0.1" ]]; then
        success "Ollama correctly bound to localhost"
    elif [[ "$CURRENT_BIND" == "0.0.0.0" ]]; then
        log "Fixing Ollama binding to localhost..."

        sudo mkdir -p /etc/systemd/system/ollama.service.d
        sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null << 'EOF'
[Service]
Environment="OLLAMA_HOST=127.0.0.1:11434"
EOF

        sudo systemctl daemon-reload
        sudo systemctl restart ollama

        sleep 3
        success "Ollama rebound to localhost"
    else
        log "Ollama not running or port not detected"
    fi
}

# Pull default model
pull_model() {
    log "Pulling model: $DEFAULT_MODEL"
    ollama pull "$DEFAULT_MODEL"
    success "Model $DEFAULT_MODEL downloaded"
}

# Create optimized model
create_optimized_model() {
    log "Creating optimized OPENCLAW model..."

    cat > /tmp/Modelfile.openclaw << 'EOF'
FROM llama3.2:3b

# Parameters optimized for OPENCLAW
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER num_ctx 4096
PARAMETER num_predict 2048
PARAMETER repeat_penalty 1.1
PARAMETER stop "<|eot_id|>"
PARAMETER stop "<|end_of_text|>"

# System prompt
SYSTEM """
Eres un agente especializado del sistema OPENCLAW.

Tu función es asistir de manera precisa, concisa y profesional.

Directrices:
- Responde de forma clara y directa
- Cuando ejecutes comandos, verifica antes de actuar
- Si no estás seguro, solicita aclaración
- Documenta tus decisiones
- Prioriza la seguridad y precisión

Formato de respuestas:
- Usa markdown cuando sea apropiado
- Estructura respuestas largas en secciones
- Incluye ejemplos cuando ayude a la comprensión
"""
EOF

    ollama create openclaw-llama32 -f /tmp/Modelfile.openclaw
    success "Created model: openclaw-llama32"
    rm /tmp/Modelfile.openclaw
}

# List models
list_models() {
    log "Installed models:"
    ollama list
}

# Test model
test_model() {
    log "Testing model..."
    response=$(ollama run openclaw-llama32 "Responde solo con 'OK'" 2>/dev/null || true)
    if [[ "$response" == *"OK"* ]]; then
        success "Model test passed"
    else
        error "Model test failed"
    fi
}

# Verify API
verify_api() {
    log "Verifying API..."
    if curl -s http://127.0.0.1:11434/api/version | grep -q "version"; then
        success "API responding correctly"
    else
        error "API not responding"
    fi
}

# Main
main() {
    echo "============================================================"
    echo "  OPENCLAW Ollama Setup"
    echo "============================================================"
    echo ""

    if ! check_ollama; then
        error "Please install Ollama first: curl -fsSL https://ollama.com/install.sh | sh"
        exit 1
    fi

    ensure_localhost
    pull_model
    create_optimized_model
    list_models
    test_model
    verify_api

    echo ""
    echo "============================================================"
    echo "  Setup Complete!"
    echo "============================================================"
    echo ""
    echo "Available models:"
    echo "  - llama3.2:3b (base)"
    echo "  - openclaw-llama32 (optimized)"
    echo ""
    echo "Usage:"
    echo "  ollama run openclaw-llama32"
    echo "  curl http://127.0.0.1:11434/api/chat -d '{...}'"
}

main "$@"
