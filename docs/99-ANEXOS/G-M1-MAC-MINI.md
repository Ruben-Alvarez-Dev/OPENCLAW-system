# Guía de Despliegue en M1/M2/M3 Mac Mini (Apple Silicon)

**ID:** DOC-ANX-M1M-001
**Versión:** 1.0
**Fecha:** 2026-03-10
**Hardware:** Apple Silicon (ARM64)

---

## Resumen

Esta guía proporciona instrucciones específicas para desplegar OPENCLAW-system en Mac Mini con Apple Silicon (M1/M2/M3). Las diferencias principales con respecto a Ubuntu son:

- Arquitectura ARM64 nativa
- Memoria unificada (GPU + CPU compartidas)
- launchd en lugar de systemd
- Homebrew como gestor de paquetes
- Docker Desktop o Colima para contenedores

---

## 1. Requisitos de Hardware

### Mínimo

| Componente | Especificación |
|------------|----------------|
| Chip | M1 (8 cores) |
| RAM | 8 GB (unificada) |
| Almacenamiento | 256 GB SSD |
| macOS | Ventura 13.0+ |

### Recomendado

| Componente | Especificación |
|------------|----------------|
| Chip | M2 Pro o M3 (10+ cores) |
| RAM | 16 GB (unificada) |
| Almacenamiento | 512 GB SSD |
| macOS | Sonoma 14.0+ |

### Ventajas de Apple Silicon

1. **Memoria unificada**: GPU y CPU comparten memoria, ideal para LLMs
2. **Neural Engine**: Aceleración hardware para ML
3. **Eficiencia energética**: Menor consumo que VPS equivalente
4. **Rendimiento sostenido**: Sin thermal throttling en Mac Mini

---

## 2. Instalación de Dependencias

### 2.1 Homebrew

```bash
# Instalar Homebrew si no existe
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Añadir a PATH (Apple Silicon)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Verificar
brew --version
```

### 2.2 Node.js v23.11.1

```bash
# Instalar nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Recargar shell
source ~/.zshrc

# Instalar Node.js (compilación ARM64 nativa)
nvm install v23.11.1
nvm alias default v23.11.1
nvm use default

# Verificar arquitectura
node -p "process.arch"
# Debe mostrar: arm64

# Verificar versión
node --version
# Debe mostrar: v23.11.1
```

### 2.3 pnpm v10.23.0

```bash
npm install -g pnpm@10.23.0
pnpm setup
source ~/.zshrc

# Verificar
pnpm --version
```

### 2.4 Git

```bash
# macOS incluye Git, pero actualizar via Homebrew
brew install git

# Configurar
git config --global user.name "OpenClaw System"
git config --global user.email "openclaw@tudominio.com"
git config --global init.defaultBranch main
```

---

## 3. Docker en Apple Silicon

### Opción A: Docker Desktop (Recomendado para principiantes)

```bash
# Instalar Docker Desktop
brew install --cask docker

# Abrir Docker Desktop (primera vez)
open /Applications/Docker.app

# Esperar a que inicie (verificar en barra de menú)

# Verificar
docker --version
docker info | grep Architecture
# Debe mostrar: arm64
```

**Configuración de recursos:**
1. Docker Desktop → Settings → Resources
2. CPUs: 6 (dejar 2 para macOS)
3. Memory: 8 GB (dejar 8 GB para macOS)
4. Swap: 2 GB

### Opción B: Colima (Más ligero, CLI)

```bash
# Instalar Colima
brew install colima

# Iniciar con configuración optimizada
colima start \
  --cpu 6 \
  --memory 8 \
  --disk 100 \
  --arch aarch64 \
  --vm-type vz

# Verificar
colima status
docker info | grep Architecture
```

**Ventajas de Colima:**
- Menor consumo de recursos
- Integración nativa con macOS Virtualization framework
- Sin interfaz gráfica (más eficiente)

### Opción C: Lima (Alternativa open-source)

```bash
brew install lima
limactl start --name=default --vm-type=vz --arch=aarch64
limactl shell default
```

---

## 4. Ollama en Apple Silicon

### 4.1 Instalación

```bash
# Descargar e instalar
curl -fsSL https://ollama.com/install.sh | sh

# O via Homebrew
brew install ollama

# Iniciar servicio
ollama serve &

# Verificar
ollama --version
```

### 4.2 Optimización para Apple Silicon

Ollama en Apple Silicon usa **Metal** (GPU de Apple) automáticamente:

```bash
# Verificar que usa Metal
ollama ps
# Debe mostrar: "GPU: Apple M1/M2/M3"

# Descargar modelo optimizado
ollama pull llama3.2:3b

# Verificar rendimiento
time ollama run llama3.2:3b "Responde solo con OK"
# En M1: ~1-2 segundos
# En M2 Pro: <1 segundo
```

### 4.3 Configuración de Memoria

La memoria unificada de Apple Silicon permite usar GPU + CPU:

```bash
# Configurar límite de memoria para Ollama
# (Opcional, por defecto usa toda la disponible)

# Para Mac con 16GB RAM, reservar 8GB para el sistema:
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_NUM_PARALLEL=1
```

---

## 5. PM2 en macOS

### 5.1 Instalación

```bash
npm install -g pm2@latest

# Verificar versión (>= 5.4.3)
pm2 --version
```

### 5.2 Configuración de Startup con launchd

macOS usa **launchd** en lugar de systemd:

```bash
# Generar plist de launchd
pm2 startup launchd

# El comando mostrará algo como:
# sudo env PATH=$PATH:/opt/homebrew/bin pm2 startup launchd -u TU_USUARIO --hp /Users/TU_USUARIO

# Ejecutar el comando mostrado
sudo env PATH=$PATH:/opt/homebrew/bin pm2 startup launchd -u $USER --hp $HOME

# Guardar configuración
pm2 save
```

### 5.3 Archivo plist Generado

PM2 crea un archivo plist en:
```
~/Library/LaunchAgents/pm2.$USER.plist
```

**Verificar:**
```bash
# Ver si está cargado
launchctl list | grep pm2

# Ver contenido
cat ~/Library/LaunchAgents/pm2.$USER.plist
```

### 5.4 Comandos de Control

```bash
# Cargar servicio manualmente
launchctl load ~/Library/LaunchAgents/pm2.$USER.plist

# Descargar servicio
launchctl unload ~/Library/LaunchAgents/pm2.$USER.plist

# Ver estado
pm2 status

# Reiniciar
pm2 restart all
```

---

## 6. Instalación de OPENCLAW-system

### 6.1 Preparar Directorios

```bash
# Crear estructura
mkdir -p ~/projects
mkdir -p ~/.openclaw/{config,data,logs,plugins,tmp}
mkdir -p ~/.openclaw/config/gears
mkdir -p ~/.openclaw/data/{memory,knowledge}

# Permisos
chmod -R 750 ~/.openclaw
```

### 6.2 Clonar y Construir

```bash
cd ~/projects
git clone https://github.com/openclaw/openclaw.git
cd openclaw

# Instalar dependencias (ARM64 nativo)
pnpm install --frozen-lockfile

# Build core-only
node scripts/tsdown-build.mjs

# Verificar que no hay errores de arquitectura
file dist/cli/openclaw.js

# Instalar globalmente
npm link

# Verificar
openclaw --version
```

### 6.3 Configuración de Environment

```bash
# Crear archivo .env
cat > ~/.openclaw/config/.env << 'EOF'
# === CONFIGURACIÓN OPENCLAW - macOS Apple Silicon ===
OPENCLAW_ENCRYPTION_KEY=$(openssl rand -hex 24)
GATEWAY_TOKEN=$(openssl rand -hex 24)

# Gateway
GATEWAY_URL=ws://127.0.0.1:18789
LOG_LEVEL=info
NODE_ENV=production

# Ollama local (Metal acelerado)
OLLAMA_HOST=127.0.0.1:11434
EOF

# Generar tokens
sed -i '' "s/\$(openssl rand -hex 24)/$(openssl rand -hex 24)/g" ~/.openclaw/config/.env
sed -i '' "s/\$(openssl rand -hex 24)/$(openssl rand -hex 24)/g" ~/.openclaw/config/.env

# Permisos seguros
chmod 600 ~/.openclaw/config/.env
```

### 6.4 Configurar ecosystem.config.js

```bash
cat > ~/projects/openclaw/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'sis-gateway',
      script: 'dist/cli/openclaw.js',
      args: 'gateway start --port 18789',
      cwd: '/Users/' + process.env.USER + '/projects/openclaw',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        LOG_LEVEL: 'info'
      },
      env_file: '/Users/' + process.env.USER + '/.openclaw/config/.env',
      error_file: '/Users/' + process.env.USER + '/.openclaw/logs/gateway-error.log',
      out_file: '/Users/' + process.env.USER + '/.openclaw/logs/gateway-out.log',
      time: true
    },
    {
      name: 'sis-director',
      script: 'dist/cli/openclaw.js',
      args: 'gear start director --gateway ws://127.0.0.1:18789',
      cwd: '/Users/' + process.env.USER + '/projects/openclaw',
      instances: 1,
      autorestart: true,
      max_memory_restart: '1G',
      env_file: '/Users/' + process.env.USER + '/.openclaw/config/.env',
      error_file: '/Users/' + process.env.USER + '/.openclaw/logs/director-error.log',
      out_file: '/Users/' + process.env.USER + '/.openclaw/logs/director-out.log',
      time: true
    },
    {
      name: 'sis-ejecutor',
      script: 'dist/cli/openclaw.js',
      args: 'gear start ejecutor --gateway ws://127.0.0.1:18789',
      cwd: '/Users/' + process.env.USER + '/projects/openclaw',
      instances: 1,
      autorestart: true,
      max_memory_restart: '2G',
      env_file: '/Users/' + process.env.USER + '/.openclaw/config/.env',
      error_file: '/Users/' + process.env.USER + '/.openclaw/logs/ejecutor-error.log',
      out_file: '/Users/' + process.env.USER + '/.openclaw/logs/ejecutor-out.log',
      time: true
    },
    {
      name: 'sis-archivador',
      script: 'dist/cli/openclaw.js',
      args: 'gear start archivador --gateway ws://127.0.0.1:18789',
      cwd: '/Users/' + process.env.USER + '/projects/openclaw',
      instances: 1,
      autorestart: true,
      max_memory_restart: '1G',
      env_file: '/Users/' + process.env.USER + '/.openclaw/config/.env',
      error_file: '/Users/' + process.env.USER + '/.openclaw/logs/archivador-error.log',
      out_file: '/Users/' + process.env.USER + '/.openclaw/logs/archivador-out.log',
      time: true
    }
  ]
};
EOF
```

### 6.5 Iniciar Servicios

```bash
cd ~/projects/openclaw

# Iniciar servicios
pm2 start ecosystem.config.js

# Verificar
pm2 status

# Guardar para persistencia
pm2 save

# Verificar startup
pm2 startup
```

---

## 7. Consideraciones Específicas de macOS

### 7.1 Suspensión y Sleep

macOS puede suspender procesos en sleep:

```bash
# Evitar que Mac entre en sleep durante operaciones largas
caffeinate -i &

# O usar pmset para deshabilitar sleep temporalmente
sudo pmset -a disablesleep 1

# Restaurar sleep
sudo pmset -a disablesleep 0
```

### 7.2 Firewall de macOS

```bash
# Verificar estado del firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# Habilitar (opcional)
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Añadir excepción para Node.js
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/bin/node
```

### 7.3 Permisos de Acceso a Disco

Otorgar permisos a Terminal/iTerm2:
1. System Preferences → Privacy & Security → Full Disk Access
2. Añadir Terminal.app o iTerm.app

### 7.4 Variables de Entorno Persistentes

En macOS, usar `~/.zshrc` o `~/.zprofile`:

```bash
# Añadir a ~/.zshrc
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
echo 'export PNPM_HOME="$HOME/.local/share/pnpm"' >> ~/.zshrc
echo 'export PATH="$PNPM_HOME:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

---

## 8. Rendimiento y Optimización

### 8.1 Monitoreo de Recursos

```bash
# Ver uso de memoria unificada
sudo powermetrics --samplers smc -i1 -n1

# Ver uso de GPU
sudo powermetrics --samplers gpu_power -i1 -n1

# Ver temperatura
sudo powermetrics --samplers smc -i1 -n1 | grep -i temp
```

### 8.2 Ajustes para Modelos LLM

Con 16GB de RAM unificada:
- Llama 3.2 (3B): ~2GB → Rápido, alta concurrencia
- Llama 3.1 (8B): ~5GB → Buen balance
- Llama 3.1 (70B): No recomendado (requiere ~40GB)

```bash
# Modelos recomendados para M1/M2 con 16GB
ollama pull llama3.2:3b      # Rápido, buena calidad
ollama pull mistral:7b       # Buena para código
ollama pull codellama:7b     # Especializado código
```

### 8.3 Limitar Recursos de Docker

```bash
# Si usas Docker Desktop, configurar límites
# Docker Desktop → Settings → Resources:
# - CPUs: 6 (dejar 2 para macOS)
# - Memory: 8 GB
# - Swap: 2 GB

# Si usas Colima, ya configurado en inicio
colima start --cpu 6 --memory 8
```

---

## 9. Troubleshooting Específico macOS

### 9.1 Error: "bad CPU type in executable"

```bash
# Causa: Binario x86_64 en Mac ARM64
# Solución: Reinstalar con arquitectura correcta

# Verificar arquitectura de Node
node -p "process.arch"
# Debe ser: arm64

# Si muestra x64, reinstalar:
nvm uninstall v23.11.1
nvm install v23.11.1
nvm alias default v23.11.1
```

### 9.2 Error: "EACCES permission denied"

```bash
# macOS puede tener permisos restrictivos
# Solución: Corregir ownership

sudo chown -R $(whoami) ~/.openclaw
sudo chown -R $(whoami) ~/projects/openclaw
chmod -R 755 ~/projects/openclaw
```

### 9.3 Docker Desktop Lento

```bash
# Verificar que usa Virtualization Framework
docker info | grep "Operating System"

# Si muestra "Docker Desktop", verificar settings:
# - Usar Virtualization Framework: ON
# - Usar containerd: ON (más rápido)

# Alternativa: Usar Colima (ver sección 3)
```

### 9.4 Ollama No Detecta GPU

```bash
# Verificar que Metal está disponible
ollama ps

# Si no muestra GPU:
# 1. Actualizar macOS
# 2. Actualizar Ollama
brew upgrade ollama

# Verificar drivers Metal
system_profiler SPDisplaysDataType
```

---

## 10. Checklist de Instalación

```markdown
## Pre-Instalación
- [ ] macOS actualizado (Ventura 13.0+)
- [ ] Xcode Command Line Tools instalado
- [ ] Homebrew configurado

## Dependencias
- [ ] Node.js v23.11.1 (ARM64)
- [ ] pnpm v10.23.0
- [ ] Docker Desktop o Colima
- [ ] PM2 >= 5.4.3
- [ ] Ollama

## Configuración
- [ ] Directorio ~/.openclaw creado
- [ ] .env con tokens generados
- [ ] ecosystem.config.js configurado
- [ ] launchd plist cargado

## Verificación
- [ ] `pm2 status` muestra 4 servicios online
- [ ] `ollama ps` muestra GPU detectada
- [ ] `curl http://127.0.0.1:18789/health` responde
```

---

## 11. Comandos de Referencia Rápida

```bash
# Iniciar todo
pm2 start all && ollama serve &

# Detener todo
pm2 stop all

# Ver estado
pm2 status && ollama ps

# Logs
pm2 logs --lines 50

# Reiniciar
pm2 restart all

# Verificar salud
curl http://127.0.0.1:18789/health
curl http://127.0.0.1:11434/api/version
```

---

**Documento:** Guía M1/M2/M3 Mac Mini
**ID:** DOC-ANX-M1M-001
**Versión:** 1.0
**Fecha:** 2026-03-10
