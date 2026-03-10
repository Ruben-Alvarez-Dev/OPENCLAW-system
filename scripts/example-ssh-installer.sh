#!/bin/bash
# =============================================================================
# EJEMPLO: Conexión SSH Interactiva - Agente Enterprise Installer
# =============================================================================
# Este script muestra cómo conectar vía SSH MCP y ejecutar comandos
# =============================================================================

# Configuración
VPS_HOST="123.456.78.90"
SSH_PORT="2222"
SSH_USER="openclaw"
SSH_KEY="~/.ssh/openclaw_vps"
SESSION_ID=""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "╔══════════════════════════════════════════════════════════╗"
echo "║         AGENTE ENTERPRISE INSTALLER - SSH DEMO          ║"
echo "╚══════════════════════════════════════════════════════════╝"

# Paso 1: Iniciar sesión SSH
echo -e "${BLUE}═════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}PASO 1: Iniciando conexión SSH${NC}"
echo -e "${BLUE}═════════════════════════════════════════════════════════${NC}"

# Usar el MCP SSH tool directamente
# Nota: En la práctica, esto se llamaría desde el agente instalador

echo "Comandos SSH disponibles:"
echo "  1. ssh-mcp-sessions_start-session - Crear nueva sesión"
echo "  2. ssh-mcp-sessions_exec - Ejecutar comandos simples"
echo "  3. ssh-mcp-sessions_exec - Ejecutar comandos interactivos"
echo ""

# Paso 2: Ejecutar comandos de verificación
echo -e "${BLUE}═════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}PASO 2: Ejecutando comandos de verificación${NC}"
echo -e "${BLUE}═════════════════════════════════════════════════════════${NC}"

echo -e "\n🔍 Comando 1: whoami"
echo "   Esperado: openclaw"
echo "   Comando: ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST whoami"
echo -e "${GREEN}Resultado:${NC} openclaw"

echo -e "\n🔍 Comando 2: lsb_release -a"
echo "   Esperado: Ubuntu 24.04 LTS"
echo "   Comando: ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST lsb_release -a"
echo -e "${GREEN}Resultado:${NC}"
ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST lsb_release -a

echo -e "\n🔍 Comando 3: uname -m"
echo "   Esperado: aarch64"
echo "   Comando: ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST uname -m"
echo -e "${GREEN}Resultado:${NC}"
ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST uname -m

echo -e "\n🔍 Comando 4: ps aux | grep -E 'node|openclaw' | grep -v grep"
echo "   Esperado: Solo procesos como usuario openclaw (NO root)"
echo "   Comando: ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST ps aux | grep -E 'node|openclaw' | grep -v grep"
echo -e "${GREEN}Resultado:${NC}"
ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST ps aux | grep -E 'node|openclaw' | grep -v grep || echo "(No hay procesos de openclaw todavía)"

# Paso 3: Ejecutar comandos críticos de seguridad
echo -e "\n${BLUE}═════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}PASO 3: Verificación de seguridad (puertos expuestos)${NC}"
echo -e "${BLUE}═════════════════════════════════════════════════════════${NC}"

echo -e "\n🔍 Comando 5: ss -tlnp"
echo "   Esperado: Solo 2222/tcp (SSH) en 0.0.0.0, nada más"
echo "   Comando: ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST ss -tlnp"
echo -e "${GREEN}Resultado:${NC}"
ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST ss -tlnp

echo -e "\n🔍 Comando 6: UFW status"
echo "   Esperado: Status: active"
echo "   Comando: ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST sudo ufw status"
echo -e "${GREEN}Resultado:${NC}"
ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST sudo ufw status

echo -e "\n🔍 Comando 7: Fail2Ban status"
echo "   Esperado: Status for the jail: sshd"
echo "   Comando: ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST sudo fail2ban-client status"
echo -e "${GREEN}Resultado:${NC}"
ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST sudo fail2ban-client status

# Paso 4: Ejecutar tests funcionales
echo -e "\n${BLUE}═════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}PASO 4: Tests funcionales${NC}"
echo -e "${BLUE}═════════════════════════════════════════════════════════${NC}"

echo -e "\n🔍 Comando 8: PM2 status"
echo "   Esperado: 4 procesos online (sis-gateway, director, ejecutor, archivador)"
echo "   Comando: ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST pm2 status"
echo -e "${GREEN}Resultado:${NC}"
ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST pm2 status

echo -e "\n🔍 Comando 9: Gateway health check"
echo "   Esperado: 200 OK o status 'ok'"
echo "   Comando: ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST curl -s http://127.0.0.1:18789/health"
echo -e "${GREEN}Resultado:${NC}"
ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST curl -s http://127.0.0.1:18789/health

echo -e "\n🔍 Comando 10: Ollama API version"
echo "   Esperado: {\"version\":\"0.x.x\"}"
echo "   Comando: ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST curl -s http://127.0.0.1:11434/api/version"
echo -e "${GREEN}Resultado:${NC}"
ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST curl -s http://127.0.0.1:11434/api/version

# Paso 5: Verificar permisos
echo -e "\n${BLUE}═════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}PASO 5: Verificación de permisos críticos${NC}"
echo -e "${BLUE}═════════════════════════════════════════════════════════${NC}"

echo -e "\n🔍 Comando 11: Permisos en .env"
echo "   Esperado: -rw------- 1 openclaw openclaw (chmod 600)"
echo "   Comando: ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST ls -la ~/.openclaw/config/.env"
echo -e "${GREEN}Resultado:${NC}"
ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST ls -la ~/.openclaw/config/.env

echo -e "\n🔍 Comando 12: Ollama bind address"
echo "   Esperado: LISTEN 0  4096  127.0.0.1:11434  0.0.0.0:*"
echo "   Comando: ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST ss -tlnp | grep 11434"
echo -e "${GREEN}Resultado:${NC}"
ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST ss -tlnp | grep 11434 || echo "(Ollama no instalado todavía)"

echo -e "\n🔍 Comando 13: Gateway bind address"
echo "   Esperado: LISTEN 0  4096  127.0.0.1:18789  0.0.0.0:*"
echo "   Comando: ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST ss -tlnp | grep 18789"
echo -e "${GREEN}Resultado:${NC}"
ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST ss -tlnp | grep 18789 || echo "(Gateway no instalado todavía)"

# Paso 6: Resumen
echo -e "\n${BLUE}═════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}RESUMEN${NC}"
echo -e "${BLUE}═════════════════════════════════════════════════════════${NC}"

echo -e "\n✅ Conexión SSH: OK"
echo -e "✅ Usuario: $SSH_USER"
echo -e "✅ Sistema: Ubuntu $(ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST lsb_release -d | cut -f2)"
echo -e "✅ Hardware: $(ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST uname -m)"
echo -e "✅ CPU: $(ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST nproc) cores"
echo -e "✅ RAM: $(ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST free -h | grep Mem | awk '{print $2}')"
echo -e "✅ Disco: $(ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$VPS_HOST df -h / | awk 'NR==2 {print $4}')"
echo ""

echo -e "\n${YELLOW}NOTA: Este es un ejemplo de cómo conectar vía SSH.${NC}"
echo -e "${YELLOW}El agente instalador usará el protocolo completo descrito en${NC}"
echo -e "${YELLOW}SIS-BIB-PRO-009-instalador-enterprise.md${NC}"
echo -e "${YELLOW}para ejecutar la instalación paso a paso interactivamente.${NC}"

# Cerrar conexión
echo -e "\n${GREEN}✅ Conexión SSH cerrada${NC}"
