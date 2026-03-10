# Hoja de Ruta: Instalación OPENCLAW-system en Ubuntu 24.04 LTS

**ID:** DOC-ANX-HOR-001
**Versión:** 1.1 | **Fecha:** 2026-03-10 | **Duración estimada:** 4-6 horas

---

## Visión General

Esta guía proporciona instrucciones paso a paso para instalar OPENCLAW-system en un VPS Ubuntu 24.04 LTS, con énfasis absoluto en seguridad.

### Configuración por Defecto

| Componente | Configuración |
|------------|---------------|
| **LLM** | Ollama + Llama 3.2 (3B) - Local, sin API tokens |
| **Runtime** | Node.js 23.11.1 |
| **Gestor** | pnpm 10.23.0 |
| **Procesos** | PM2 >= 5.4.3 |
| **Contenedores** | Docker CE (rootless mode) |

### Proveedores Adicionales (Opcionales)

OpenClaw soporta 30+ proveedores de IA. Puedes configurarlos cuando lo desees:
- OpenAI, Anthropic, Google AI, Z.AI, LM Studio, Ollama remoto, etc.

---

## 0. Prerequisitos

### 0.1 Requisitos del VPS

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| CPU | 2 cores | 4+ cores |
| RAM | 4 GB | 8+ GB (para Llama 3.2) |
| Disco | 40 GB SSD | 80+ GB SSD |
| Red | IPv4 público | IPv4 + IPv6 |

### 0.2 Acceso Inicial

```bash
# Conectar como root
ssh root@TU_IP_VPS
```

### 0.3 Verificar Versión de Ubuntu

```bash
lsb_release -a
```

**Output esperado:**
```
Distributor ID: Ubuntu
Description:    Ubuntu 24.04 LTS
Release:        24.04
Codename:       noble
```

---

## 1. Preparación del Sistema (45 min)

### 1.1 Actualización Completa del Sistema

**Tiempo:** 15 min

```bash
# PASO 1: Actualizar lista de paquetes
apt update

# Output esperado:
# Hit:1 http://archive.ubuntu.com/ubuntu noble InRelease
# ...
# Reading package lists... Done

# PASO 2: Actualizar paquetes instalados
apt upgrade -y

# Output esperado:
# Calculating upgrade... Done
# ...
# Done.

# PASO 3: Actualización de distribución (si hay)
apt dist-upgrade -y

# PASO 4: Limpiar paquetes innecesarios
apt autoremove -y
apt autoclean

# PASO 5: Verificar si hay reinicio pendiente
if [ -f /var/run/reboot-required ]; then
    echo "⚠️  REINICIO REQUERIDO - Ejecutar: reboot"
else
    echo "✅ No requiere reinicio"
fi
```

**Troubleshooting:**
```bash
# Si hay bloqueo de apt:
rm /var/lib/apt/lists/lock
rm /var/lib/dpkg/lock-frontend
rm /var/lib/dpkg/lock
dpkg --configure -a
```

### 1.2 Creación de Usuario Secundario

**Tiempo:** 10 min
**IMPORTANTE:** NUNCA usar root para operaciones diarias

```bash
# PASO 1: Crear usuario
adduser openclaw

# Input interactivo:
# New password: [TU_CONTRASEÑA_SEGURA]
# Retype password: [TU_CONTRASEÑA_SEGURA]
# Full Name: OpenClaw System User
# Room Number: [Enter]
# Work Phone: [Enter]
# Home Phone: [Enter]
# Other: [Enter]
# Is the information correct? [Y/n] Y

# PASO 2: Añadir a grupos necesarios
usermod -aG sudo,docker openclaw

# PASO 3: Configurar directorio home
chmod 750 /home/openclaw
chown openclaw:openclaw /home/openclaw

# PASO 4: Verificar creación
id openclaw

# Output esperado:
# uid=1000(openclaw) gid=1000(openclaw) groups=1000(openclaw),27(sudo),999(docker)
```

### 1.3 Configuración de SSH Hardening

**Tiempo:** 20 min

```bash
# PASO 1: Backup de configuración original
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)

# PASO 2: Generar claves SSH EN TU MÁQUINA LOCAL (no en el VPS)
# En tu ordenador local:
ssh-keygen -t ed25519 -C "openclaw@vps" -f ~/.ssh/openclaw_vps

# Output esperado:
# Generating public/private ed25519 key pair.
# Enter passphrase (empty for no passphrase): [OPCIONAL]
# Your identification has been saved in ~/.ssh/openclaw_vps
# Your public key has been saved in ~/.ssh/openclaw_vps.pub

# PASO 3: Copiar clave pública al servidor (DESDE TU MÁQUINA LOCAL)
ssh-copy-id -i ~/.ssh/openclaw_vps.pub openclaw@TU_IP_VPS

# Output esperado:
# Number of key(s) added: 1

# PASO 4: Verificar acceso con clave (EN NUEVA TERMINAL, NO CERRAR LA ACTUAL)
ssh -i ~/.ssh/openclaw_vps openclaw@TU_IP_VPS

# Si funciona, continúa. Si NO funciona, NO cierres la sesión root.

# PASO 5: Configurar sshd_config (como root en el VPS)
nano /etc/ssh/sshd_config
```

**Modificar estos valores en sshd_config:**

```ssh
# Puerto no estándar (elegir entre 1024-65535)
Port 2222

# NUNCA permitir root login
PermitRootLogin no

# Solo autenticación por claves
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no

# Usuarios permitidos
AllowUsers openclaw

# Configuración de seguridad
MaxAuthTries 3
LoginGraceTime 60
X11Forwarding no
ClientAliveInterval 300
ClientAliveCountMax 2

# Deshabilitar métodos inseguros
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
```

```bash
# PASO 6: Verificar sintaxis de configuración
sshd -t

# Sin output = configuración correcta

# PASO 7: Reiniciar SSH
systemctl restart sshd
systemctl status sshd

# Output esperado:
# Active: active (running)

# PASO 8: PROBAR ACCESO EN NUEVA TERMINAL (NO CERRAR LA ACTUAL)
ssh -p 2222 -i ~/.ssh/openclaw_vps openclaw@TU_IP_VPS

# Si funciona correctamente, puedes cerrar la sesión root
```

**Troubleshooting:**
```bash
# Si pierdes acceso SSH:
# 1. Accede via consola del proveedor VPS
# 2. Restaura backup: cp /etc/ssh/sshd_config.backup.YYYYMMDD /etc/ssh/sshd_config
# 3. systemctl restart sshd
```

### 1.4 Configuración de Firewall UFW

**Tiempo:** 10 min

```bash
# Continuar como usuario openclaw con sudo

# PASO 1: Verificar estado actual
sudo ufw status verbose

# Output esperado: Status: inactive

# PASO 2: Configurar política por defecto
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Output esperado:
# Default incoming direction changed to 'deny'
# Default outgoing direction changed to 'allow'

# PASO 3: Permitir SSH en puerto personalizado
sudo ufw allow 2222/tcp comment 'SSH - OpenClaw admin'

# IMPORTANTE: Si usarás puertos adicionales, añadirlos ANTES de habilitar:
# sudo ufw allow 80/tcp comment 'HTTP'
# sudo ufw allow 443/tcp comment 'HTTPS'

# PASO 4: Verificar reglas antes de habilitar
sudo ufw show added

# Output esperado:
# Added user rules (see 'ufw status' for running firewall):
# 2222/tcp                   ALLOW IN   Anywhere

# PASO 5: Habilitar firewall
sudo ufw enable

# Output esperado:
# Command may disrupt existing ssh connections.
# Proceed with operation (y|n)? y
# Firewall is active and enabled on system startup

# PASO 6: Verificar estado
sudo ufw status numbered

# Output esperado:
# Status: active
#      To                         Action      From
# [ 1] 2222/tcp                   ALLOW IN    Anywhere
```

### 1.5 Instalación de Fail2Ban

**Tiempo:** 10 min

```bash
# PASO 1: Instalar fail2ban
sudo apt install fail2ban -y

# PASO 2: Crear configuración local
sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
# Tiempo de baneo (1 hora)
bantime = 1h
# Ventana de tiempo para contar intentos
findtime = 10m
# Máximo de intentos antes de baneo
maxretry = 3
# IPs a ignorar (localhost)
ignoreip = 127.0.0.1/8

[sshd]
enabled = true
port = 2222
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
# Baneo más largo para SSH (24 horas)
bantime = 24h
EOF

# PASO 3: Habilitar y reiniciar
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

# PASO 4: Verificar estado
sudo fail2ban-client status sshd

# Output esperado:
# Status for the jail: sshd
# |- Filter
# |  |- Currently failed: 0
# |  |- Total failed:     0
# `- Actions
#    |- Currently banned: 0
#    |- Total banned:     0
```

---

## 2. Instalación de Dependencias (1.5 horas)

### 2.1 Instalación de Node.js v23.11.1

**Tiempo:** 20 min

```bash
# Cambiar a usuario openclaw
su - openclaw

# PASO 1: Instalar nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Output esperado:
# => Close and reopen your terminal to start using nvm

# PASO 2: Recargar shell
source ~/.bashrc

# Si no funciona:
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# PASO 3: Verificar instalación de nvm
nvm --version

# Output esperado: 0.40.1

# PASO 4: Instalar Node.js 23.11.1
nvm install v23.11.1

# Output esperado:
# Downloading and installing node v23.11.1...
# Now using node v23.11.1 (npm v10.x.x)

# PASO 5: Establecer como versión por defecto
nvm alias default v23.11.1
nvm use default

# PASO 6: Verificar versiones
node --version
# Output esperado: v23.11.1

npm --version
# Output esperado: 10.x.x

# PASO 7: Verificar ubicación
which node
# Output esperado: /home/openclaw/.nvm/versions/node/v23.11.1/bin/node
```

**Troubleshooting:**
```bash
# Si "nvm: command not found":
# Añadir a .bashrc manualmente:
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> ~/.bashrc
source ~/.bashrc
```

### 2.2 Instalación de pnpm v10.23.0

**Tiempo:** 5 min

```bash
# PASO 1: Instalar pnpm globalmente
npm install -g pnpm@10.23.0

# Output esperado:
# added 1 package in 2s

# PASO 2: Verificar instalación
pnpm --version

# Output esperado: 10.23.0

# PASO 3: Configurar pnpm
pnpm setup

# Output esperado:
# The setup was successful. Run `source ~/.bashrc` to update your shell.

# PASO 4: Recargar shell
source ~/.bashrc

# PASO 5: Verificar PATH
echo $PATH | grep -o ".local/share/pnpm"
# Output esperado: .local/share/pnpm
```

### 2.3 Instalación de Docker CE (Rootless Mode)

**Tiempo:** 30 min

```bash
# PASO 1: Instalar dependencias (como sudo)
sudo apt install -y ca-certificates curl gnupg lsb-release

# PASO 2: Crear directorio para claves GPG
sudo install -m 0755 -d /etc/apt/keyrings

# PASO 3: Descargar clave GPG de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# PASO 4: Añadir repositorio de Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# PASO 5: Actualizar e instalar Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# PASO 6: Habilitar servicio Docker
sudo systemctl enable docker
sudo systemctl start docker

# PASO 7: Verificar instalación
docker --version

# Output esperado: Docker version 27.x.x, build xxxxxxx

# PASO 8: Configurar rootless mode (MÁS SEGURO)
# Instalar dependencias para rootless
sudo apt install -y uidmap

# Configurar rootless como usuario openclaw
dockerd-rootless-setuptool.sh install

# Output esperado:
# [INFO] Creating /home/openclaw/.config/systemd/user/docker.service
# [INFO] starting systemd service docker.service
# [INFO] Successfully installed rootless docker

# PASO 9: Configurar variables de entorno
cat >> ~/.bashrc << 'EOF'

# Docker rootless configuration
export PATH=/usr/bin:$PATH
export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
EOF

source ~/.bashrc

# PASO 10: Verificar rootless mode
docker context ls

# Output esperado:
# NAME            DESCRIPTION                               DOCKER ENDPOINT
# default *       Current DOCKER_HOST-based configuration    unix:///run/user/1000/docker.sock

# PASO 11: Test de funcionamiento
docker run --rm hello-world

# Output esperado:
# Hello from Docker!
# This message shows that your installation appears to be working correctly.
```

**Troubleshooting:**
```bash
# Si dockerd-rootless-setuptool.sh no existe:
# Necesitas instalar docker-ce-rootless-extras
sudo apt install -y docker-ce-rootless-extras

# Si hay error de permisos:
sudo systemctl restart docker
```

### 2.4 Instalación de PM2 >= 5.4.3

**Tiempo:** 10 min

```bash
# PASO 1: Instalar PM2 globalmente
npm install -g pm2@latest

# Output esperado:
# added 1 package in 3s

# PASO 2: Verificar versión (DEBE ser >= 5.4.3)
pm2 --version

# Output esperado: 5.4.3 o superior

# IMPORTANTE: Si la versión es menor, forzar actualización
npm update -g pm2

# PASO 3: Configurar startup script
pm2 startup systemd -u openclaw --hp /home/openclaw

# Output esperado:
# [PM2] You have to run this command as administrator:
# sudo env PATH=$PATH:...

# EJECUTAR el comando que te muestra (será algo como):
sudo env PATH=$PATH:/home/openclaw/.nvm/versions/node/v23.11.1/bin /home/openclaw/.nvm/versions/node/v23.11.1/lib/node_modules/pm2/bin/pm2 startup systemd -u openclaw --hp /home/openclaw

# PASO 4: Guardar configuración inicial
pm2 save

# Output esperado:
# [PM2] Saving current process list...
# [PM2] Successfully saved
```

### 2.5 Instalación de Herramientas Adicionales

**Tiempo:** 10 min

```bash
# PASO 1: Instalar utilidades útiles
sudo apt install -y git curl wget htop neofetch tree jq

# PASO 2: Configurar Git
git config --global user.name "OpenClaw System"
git config --global user.email "openclaw@tudominio.com"
git config --global init.defaultBranch main

# PASO 3: Verificar instalaciones
git --version
curl --version | head -1
jq --version
```

---

## 3. Instalación de Ollama + Llama 3.2 (1 hora)

### 3.1 Instalación de Ollama

**Tiempo:** 15 min

```bash
# PASO 1: Descargar e instalar Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Output esperado:
# >>> Installing ollama to /usr/local/bin
# >>> Creating ollama user...
# >>> Adding ollama user to video group...
# >>> Adding current user to ollama group...
# >>> Creating systemd service...
# >>> Enabling and starting ollama service...
# >>> The Ollama API is now available at 127.0.0.1:11434.

# PASO 2: Verificar que Ollama está corriendo
curl http://127.0.0.1:11434/api/version

# Output esperado:
# {"version":"0.x.x"}

# PASO 3: IMPORTANTE - Verificar que NO escucha en 0.0.0.0
ss -tlnp | grep 11434

# Output esperado:
# LISTEN 0  4096  127.0.0.1:11434  0.0.0.0:*
# ^-- Debe ser 127.0.0.1, NO 0.0.0.0

# PASO 4: Si escucha en 0.0.0.0, corregir:
sudo systemctl stop ollama
sudo mkdir -p /etc/systemd/system/ollama.service.d

sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null << 'EOF'
[Service]
Environment="OLLAMA_HOST=127.0.0.1:11434"
EOF

sudo systemctl daemon-reload
sudo systemctl start ollama

# Verificar de nuevo
ss -tlnp | grep 11434
```

### 3.2 Descargar Modelo Llama 3.2 (3B)

**Tiempo:** 15-45 min (depende de conexión)

```bash
# PASO 1: Descargar modelo
ollama pull llama3.2:3b

# Output esperado:
# pulling manifest
# pulling 6a0746a4ec7c: 100% ▕████████████████▏ 2.0 GB
# pulling 8bd5d4e6c4d4: 100% ▕████████████████▏ 1.4 KB
# ...
# success

# PASO 2: Verificar modelo instalado
ollama list

# Output esperado:
# NAME            ID              SIZE    MODIFIED
# llama3.2:3b     a80c4f...       2.0 GB  2 minutes ago

# PASO 3: Test básico de funcionamiento
ollama run llama3.2:3b "Responde solo con 'OK' y nada más"

# Output esperado: OK

# PASO 4: Salir si entra en modo interactivo
# (escribir /bye y Enter)
```

### 3.3 Optimizar Modelo para VPS

**Tiempo:** 10 min

```bash
# PASO 1: Crear Modelfile optimizado para OPENCLAW
cat > ~/Modelfile.openclaw << 'EOF'
FROM llama3.2:3b

# Parámetros optimizados para VPS con recursos moderados
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER num_ctx 4096
PARAMETER num_predict 2048
PARAMETER repeat_penalty 1.1

# System prompt para el sistema OPENCLAW
SYSTEM """
Eres un agente especializado del sistema OPENCLAW.
Tu función es asistir de manera precisa y concisa.

Directrices:
- Responde de forma clara y directa
- Cuando ejecutes comandos, verifica antes de actuar
- Si no estás seguro, pide aclaración
- Documenta tus decisiones
"""
EOF

# PASO 2: Crear modelo personalizado
ollama create openclaw-llama32 -f ~/Modelfile.openclaw

# Output esperado:
# transferring model data
# using existing layer sha256:6a0746...
# creating new layer sha256:...
# writing manifest
# success

# PASO 3: Verificar nuevo modelo
ollama list | grep openclaw

# Output esperado:
# openclaw-llama32  xyz...  2.0 GB  ...

# PASO 4: Test del modelo optimizado
ollama run openclaw-llama32 "¿Cuál es tu función en OPENCLAW?"
```

---

## 4. Instalación de OpenClaw (1 hora)

### 4.1 Preparar Directorios

**Tiempo:** 5 min

```bash
# PASO 1: Crear estructura de directorios
mkdir -p ~/projects
mkdir -p ~/.openclaw/{config,data,logs,plugins,tmp}
mkdir -p ~/.openclaw/config/gears
mkdir -p ~/.openclaw/data/{memory,knowledge}

# PASO 2: Establecer permisos
chmod -R 750 ~/.openclaw
```

### 4.2 Clonar y Construir OpenClaw

**Tiempo:** 30-45 min

```bash
# PASO 1: Ir al directorio de proyectos
cd ~/projects

# PASO 2: Clonar repositorio OpenClaw
git clone https://github.com/openclaw/openclaw.git
cd openclaw

# PASO 3: Verificar versión
git log -1 --oneline

# PASO 4: Instalar dependencias
pnpm install --frozen-lockfile

# Output esperado:
# Progress: resolved X, reused X, downloaded 0, added X
# Done in 45.2s

# PASO 5: Construir el core
node scripts/tsdown-build.mjs

# Output esperado:
# Building OpenClaw core...
# ✓ Compiled successfully
# Output: dist/

# PASO 6: Verificar build
ls -la dist/cli/

# Debe mostrar: openclaw.js y otros archivos

# PASO 7: Instalar globalmente (opcional, para CLI)
npm link

# PASO 8: Verificar instalación
openclaw --version

# Output esperado: OpenClaw 2026.3.8
```

### 4.3 Configurar Providers (Ollama como Primario)

**Tiempo:** 15 min

```bash
# PASO 1: Crear configuración de providers
# NOTA: Esta configuración funciona SIN NECESIDAD de API keys externas

cat > ~/.openclaw/config/providers.json << 'EOF'
{
  "providers": {
    "ollama": {
      "name": "ollama",
      "baseUrl": "http://127.0.0.1:11434",
      "models": {
        "llama3.2:3b": {
          "enabled": true,
          "contextWindow": 4096,
          "maxOutput": 2048,
          "temperature": 0.7
        },
        "openclaw-llama32": {
          "enabled": true,
          "contextWindow": 4096,
          "maxOutput": 2048
        }
      },
      "rateLimit": {
        "requestsPerMinute": 60
      },
      "timeout": 60000
    }
  },
  "fallback": {
    "strategy": "none",
    "order": ["ollama"],
    "maxAttempts": 3
  }
}
EOF

# PASO 2: Crear archivo de variables de entorno
cat > ~/.openclaw/config/.env << 'EOF'
# === CONFIGURACIÓN OPENCLAW ===
# Generar con: openssl rand -hex 24
OPENCLAW_ENCRYPTION_KEY=GENERAR_CON_OPENSSL
GATEWAY_TOKEN=GENERAR_CON_OPENSSL

# Gateway WebSocket
GATEWAY_URL=ws://127.0.0.1:18789

# Logging
LOG_LEVEL=info
LOG_FORMAT=json
NODE_ENV=production

# Ollama local (no necesita API key)
OLLAMA_HOST=127.0.0.1:11434

# === PROVIDERS ADICIONALES (OPCIONALES) ===
# Descomentar y configurar si se desea usar:

# --- Ollama Remoto (servidor dedicado de inferencia) ---
# OLLAMA_REMOTE_HOST=192.168.1.100:11434

# --- LM Studio (local, puerto por defecto) ---
# LMSTUDIO_HOST=127.0.0.1:1234

# --- OpenAI (requiere API key) ---
# OPENAI_API_KEY=sk-tu_api_key_openai

# --- Anthropic Claude (requiere API key) ---
# ANTHROPIC_API_KEY=sk-ant-tu_api_key_anthropic

# --- Z.AI / ZhipuAI (requiere API key) ---
# ZHIPUAI_API_KEY=tu_api_key_zhipuai

# --- Google AI (requiere API key) ---
# GOOGLE_API_KEY=tu_google_api_key

# === CANALES (OPCIONALES) ===
# TELEGRAM_BOT_TOKEN=tu_token_telegram
# DISCORD_BOT_TOKEN=tu_token_discord
EOF

# PASO 3: Generar tokens seguros
# Generar OPENCLAW_ENCRYPTION_KEY
ENCRYPTION_KEY=$(openssl rand -hex 24)
sed -i "s/GENERAR_CON_OPENSSL/$ENCRYPTION_KEY/" ~/.openclaw/config/.env

# Generar GATEWAY_TOKEN
GATEWAY_TOKEN=$(openssl rand -hex 24)
sed -i "0,/GENERAR_CON_OPENSSL/s//$GATEWAY_TOKEN/" ~/.openclaw/config/.env

# PASO 4: Verificar que no quedan placeholders
grep "GENERAR" ~/.openclaw/config/.env && echo "⚠️  Quedan placeholders por reemplazar" || echo "✅ Todos los tokens generados"

# PASO 5: Asegurar permisos
chmod 600 ~/.openclaw/config/.env

# PASO 6: Verificar permisos
ls -la ~/.openclaw/config/.env

# Output esperado:
# -rw------- 1 openclaw openclaw ... .env
```

---

## 5. Configuración del Tri-Agente OPENCLAW (30 min)

### 5.1 Configuración PM2

**Tiempo:** 15 min

```bash
# PASO 1: Crear ecosystem.config.js
cat > ~/projects/openclaw/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'sis-gateway',
      script: 'dist/cli/openclaw.js',
      args: 'gateway start --port 18789',
      cwd: '/home/openclaw/projects/openclaw',
      instances: 1,
      autorestart: true,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        LOG_LEVEL: 'info',
        GATEWAY_URL: 'ws://127.0.0.1:18789'
      },
      env_file: '/home/openclaw/.openclaw/config/.env',
      error_file: '/home/openclaw/.openclaw/logs/gateway-error.log',
      out_file: '/home/openclaw/.openclaw/logs/gateway-out.log',
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    {
      name: 'sis-director',
      script: 'dist/cli/openclaw.js',
      args: 'gear start director --gateway ws://127.0.0.1:18789',
      cwd: '/home/openclaw/projects/openclaw',
      instances: 1,
      autorestart: true,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production'
      },
      env_file: '/home/openclaw/.openclaw/config/.env',
      error_file: '/home/openclaw/.openclaw/logs/director-error.log',
      out_file: '/home/openclaw/.openclaw/logs/director-out.log',
      time: true
    },
    {
      name: 'sis-ejecutor',
      script: 'dist/cli/openclaw.js',
      args: 'gear start ejecutor --gateway ws://127.0.0.1:18789',
      cwd: '/home/openclaw/projects/openclaw',
      instances: 1,
      autorestart: true,
      max_memory_restart: '2G',
      env: {
        NODE_ENV: 'production'
      },
      env_file: '/home/openclaw/.openclaw/config/.env',
      error_file: '/home/openclaw/.openclaw/logs/ejecutor-error.log',
      out_file: '/home/openclaw/.openclaw/logs/ejecutor-out.log',
      time: true
    },
    {
      name: 'sis-archivador',
      script: 'dist/cli/openclaw.js',
      args: 'gear start archivador --gateway ws://127.0.0.1:18789',
      cwd: '/home/openclaw/projects/openclaw',
      instances: 1,
      autorestart: true,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production'
      },
      env_file: '/home/openclaw/.openclaw/config/.env',
      error_file: '/home/openclaw/.openclaw/logs/archivador-error.log',
      out_file: '/home/openclaw/.openclaw/logs/archivador-out.log',
      time: true
    }
  ]
};
EOF

# PASO 2: Verificar sintaxis del archivo
node -e "require('./ecosystem.config.js')" && echo "✅ Sintaxis correcta" || echo "❌ Error de sintaxis"
```

### 5.2 Iniciar Servicios

**Tiempo:** 10 min

```bash
# PASO 1: Ir al directorio de OpenClaw
cd ~/projects/openclaw

# PASO 2: Iniciar todos los servicios
pm2 start ecosystem.config.js

# Output esperado:
# [PM2] Applying process override
# [PM2] Process sis-gateway launched
# [PM2] Process sis-director launched
# [PM2] Process sis-ejecutor launched
# [PM2] Process sis-archivador launched

# PASO 3: Verificar estado
pm2 status

# Output esperado:
# ┌─────┬────────────────┬─────────┬─────────┐
# │ id  │ name           │ status  │ cpu     │
# ├─────┼────────────────┼─────────┼─────────┤
# │ 0   │ sis-gateway    │ online  │ 0%      │
# │ 1   │ sis-director   │ online  │ 0%      │
# │ 2   │ sis-ejecutor   │ online  │ 0%      │
# │ 3   │ sis-archivador │ online  │ 0%      │
# └─────┴────────────────┴─────────┴─────────┘

# PASO 4: Guardar configuración PM2
pm2 save

# Output esperado:
# [PM2] Saving current process list...
# [PM2] Successfully saved in /home/openclaw/.pm2/dump.pm2

# PASO 5: Verificar logs
pm2 logs --lines 10
```

---

## 6. Verificación Final (30 min)

### 6.1 Checklist de Seguridad

**Tiempo:** 15 min

```bash
# CHECKLIST DE VERIFICACIÓN

echo "=== 1. Puertos expuestos ==="
ss -tlnp
# Solo debe mostrar: 2222 (SSH), 18789 en 127.0.0.1

echo ""
echo "=== 2. Firewall activo ==="
sudo ufw status
# Status: active

echo ""
echo "=== 3. Fail2ban activo ==="
sudo fail2ban-client status

echo ""
echo "=== 4. Ollama solo localhost ==="
curl -s http://127.0.0.1:11434/api/version && echo "✅ Ollama responde en localhost"
# Verificar que NO responde desde fuera:
timeout 2 curl -s http://$(curl -s ifconfig.me):11434/api/version 2>/dev/null && echo "❌ Ollama EXPUESTO" || echo "✅ Ollama NO expuesto"

echo ""
echo "=== 5. Gateway solo localhost ==="
curl -s http://127.0.0.1:18789/health 2>/dev/null || echo "Gateway verificando..."
# Verificar que NO responde desde fuera:
timeout 2 curl -s http://$(curl -s ifconfig.me):18789/health 2>/dev/null && echo "❌ Gateway EXPUESTO" || echo "✅ Gateway NO expuesto"

echo ""
echo "=== 6. Sin procesos como root ==="
ps aux | grep -E "openclaw|node" | grep -v grep

echo ""
echo "=== 7. Permisos correctos ==="
ls -la ~/.openclaw/config/.env
# -rw------- 1 openclaw openclaw

echo ""
echo "=== 8. Actualizaciones automáticas ==="
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
# Seleccionar "Yes"
```

### 6.2 Test Funcional

**Tiempo:** 15 min

```bash
# TEST 1: Gateway responde
echo "=== Test 1: Gateway ==="
curl -v http://127.0.0.1:18789/health 2>&1 | grep -E "HTTP|connected"

# TEST 2: Ollama integrado
echo ""
echo "=== Test 2: Ollama ==="
curl -s http://127.0.0.1:11434/api/chat -d '{
  "model": "llama3.2:3b",
  "messages": [{"role": "user", "content": "Say OK only"}],
  "stream": false
}' | jq -r '.message.content'

# Output esperado: OK

# TEST 3: OpenClaw CLI
echo ""
echo "=== Test 3: OpenClaw CLI ==="
openclaw --help | head -5

# TEST 4: PM2 estable
echo ""
echo "=== Test 4: PM2 Status ==="
pm2 status

# Todos deben estar "online"

# TEST 5: Verificar logs sin errores críticos
echo ""
echo "=== Test 5: Logs (últimos errores) ==="
pm2 logs --lines 20 --err
```

---

## 7. Configuración Opcional de Providers Adicionales

### 7.1 Añadir OpenAI como Fallback

```bash
# PASO 1: Añadir API key al .env
echo 'OPENAI_API_KEY=sk-tu_api_key_real' >> ~/.openclaw/config/.env

# PASO 2: Actualizar providers.json
# Añadir sección "openai" y actualizar fallback order
# "fallback": { "order": ["ollama", "openai"] }

# PASO 3: Reiniciar servicios
pm2 restart all
```

### 7.2 Añadir LM Studio Local

```bash
# PASO 1: Añadir a .env
echo 'LMSTUDIO_HOST=127.0.0.1:1234' >> ~/.openclaw/config/.env

# PASO 2: Añadir a providers.json:
# "lmstudio": {
#   "name": "lmstudio",
#   "baseUrl": "http://127.0.0.1:1234/v1",
#   "models": { "local-model": { "enabled": true } }
# }
```

### 7.3 Añadir Ollama Remoto (Servidor Dedicado)

```bash
# PASO 1: Añadir a .env
echo 'OLLAMA_REMOTE_HOST=192.168.1.100:11434' >> ~/.openclaw/config/.env

# PASO 2: Añadir provider en providers.json:
# "ollama-remote": {
#   "name": "ollama-remote",
#   "baseUrl": "http://${OLLAMA_REMOTE_HOST}",
#   ...
# }
```

---

## 8. Mantenimiento

### 8.1 Comandos Útiles

```bash
# Ver estado de servicios
pm2 status

# Ver logs en tiempo real
pm2 logs

# Ver logs de un servicio específico
pm2 logs sis-gateway

# Reiniciar todos los servicios
pm2 restart all

# Reiniciar servicio específico
pm2 restart sis-ejecutor

# Detener todos los servicios
pm2 stop all

# Ver uso de recursos
pm2 monit

# Verificar Ollama
ollama list
ollama ps

# Actualizar modelo
ollama pull llama3.2:3b
```

### 8.2 Actualizaciones del Sistema

```bash
# Actualizar sistema operativo
sudo apt update && sudo apt upgrade -y

# Actualizar Node.js (si hay nueva versión)
nvm install node --reinstall-packages-from=node

# Actualizar PM2
npm update -g pm2
pm2 update

# Actualizar OpenClaw
cd ~/projects/openclaw
git pull
pnpm install
node scripts/tsdown-build.mjs
pm2 restart all
```

### 8.3 Backups

```bash
# Backup de configuración
tar -czvf openclaw-config-$(date +%Y%m%d).tar.gz ~/.openclaw/config/

# Backup de datos
tar -czvf openclaw-data-$(date +%Y%m%d).tar.gz ~/.openclaw/data/

# Restaurar
tar -xzvf openclaw-config-YYYYMMDD.tar.gz -C ~/
```

---

## 9. Troubleshooting

### 9.1 Problemas Comunes

| Problema | Solución |
|----------|----------|
| PM2 processes not starting | `pm2 delete all && pm2 start ecosystem.config.js` |
| Ollama connection refused | `sudo systemctl restart ollama` |
| Gateway not responding | Check port 18789: `ss -tlnp \| grep 18789` |
| Out of memory | Reduce `max_memory_restart` or add swap |
| Permission denied | Check file ownership: `chown -R openclaw:openclaw ~/.openclaw` |

### 9.2 Logs de Diagnóstico

```bash
# Ver todos los logs
pm2 logs --lines 100

# Ver logs de sistema
journalctl -u docker --no-pager -n 50
journalctl -u ollama --no-pager -n 50

# Verificar conectividad
curl -v http://127.0.0.1:11434/api/version
curl -v http://127.0.0.1:18789/health
```

---

## 10. Resumen de Configuración Final

| Componente | Configuración |
|------------|---------------|
| **Usuario** | openclaw (no root) |
| **SSH** | Puerto 2222, solo claves, sin root |
| **Firewall** | UFW activo, solo 2222/tcp |
| **Fail2Ban** | Activo, 3 intentos = 24h baneo |
| **Node.js** | v23.11.1 via nvm |
| **pnpm** | v10.23.0 |
| **Docker** | CE rootless mode |
| **PM2** | >= 5.4.3, startup configurado |
| **Ollama** | 127.0.0.1:11434, Llama 3.2 (3B) |
| **Gateway** | 127.0.0.1:18789 |
| **LLM** | Ollama local (sin API tokens) |

---

**Documento:** Hoja de Ruta Ubuntu 24.04 LTS
**ID:** DOC-ANX-HOR-001
**Versión:** 1.1
**Fecha:** 2026-03-10
