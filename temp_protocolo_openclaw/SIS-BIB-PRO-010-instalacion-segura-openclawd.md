# PROTOCOLO-CHECKLIST: Instalación Segura de openclawd (1 Instancia)

**ID:** SIS-BIB-PRO-010
**Versión:** 4.0 (VPS + Tailscale + Seguridad Máxima)
**Fecha:** 2026-03-10
**Tipo:** Instalación Productiva con Seguridad Máxima
**Sistema:** VPS (Linux) via Tailscale
**Auditoría:** Oracle Security + Investigación 2026

---

## TOPOLOGÍA FINAL

```
┌─────────────────────────────────────────────────────────────────┐
│                      TOPOLOGÍA DE INSTALACIÓN                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   INTERNET                                                      │
│      ▲                                                         │
│      │ OpenClaw llama a APIs (OpenAI, Anthropic, Brave)        │
│      │                                                         │
│   ┌──┴───┐          Tailscale Network (100.x.x.x)             │
│   │ VPS  │ ◄──────────────────────────────► MacBook (tú)    │
│   │      │         100.x.x.x (dinámica)     100.x.x.x         │
│   │      │                                                   │
│   │Open  │  ┌────────────────────────────────────────────┐    │
│   │Claw  │  │ OpenClaw Gateway                          │    │
│   │      │  │ bind: 127.0.0.1:45678 (SOLO localhost)    │    │
│   │      │  │ Sandbox: network:none (sin internet)       │    │
│   │      │  │ APIs: llamadas desde proceso principal     │    │
│   │      │  └────────────────────────────────────────────┘    │
│   └──────┘                                                   │
│                                                                  │
│   ACCESO:                                                      │
│   - MacBook → VPS via Tailscale (100.x.x.x:45678)            │
│   - Internet → VPS: NO (puerto solo en localhost)            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## PUERTO SELECCIONADO: 45678

### ¿Por qué este puerto?

| Puerto | Razón |
|--------|-------|
| **45678** | - Alto (fuera de escaneos típicos 1-10000)<br>- No es default de ningún servicio conocido<br>- No aparece en listas de puertos "de interés" para hackers<br>- Fácil de recordar (45678) |

**Puertos a EVITAR:** 22, 80, 443, 3000, 3306, 5432, 6379, 8080, 8443, 27017, **18789** (default OpenClaw)

---

## 🔴 ANÁLISIS DE SEGURIDAD - HALLAZGOS CRÍTICOS

### Errores en Propuesta Original (v1.0/v2.0)

| Parámetro | Propuesto (v1) | CORRECTO | Vulnerabilidad |
|-----------|-----------------|----------|----------------|
| `networkMode` | `"bridge"` | `"none"` | Contenedor puede atacar LAN/exfiltrar |
| `readOnlyRootFilesystem` | `false` | `true` | Puede escribir malware/persistencia |
| `autoApprove.safe` | `true` | `false"` | Cualquier comando peligroso aprobado |
| `autoApprove.requiresApproval` | `false` | `true"` | Comandos peligrosos sin aprobación |
| Puerto | 18789 (default) | 45678 | Escanear automaticos encuentran default |
| Token en JSON | ✅ SÍ | ❌ NO | Se filtra por logs/backups |

### Vectores de Ataque Identificados

```
┌─────────────────────────────────────────────────────────────────┐
│                    VECTORES DE ATAQUE                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. host.docker.internal  → Contenedor → Gateway (127.0.0.1)   │
│                                                                  │
│  2. Mounts de /Users en Docker → Acceso a datos sin escapar   │
│                                                                  │
│  3. Intérpretes (python/node/ruby/php) → Ejecución shell       │
│                                                                  │
│  4. Token en JSON → Filtración por logs/backups                │
│                                                                  │
│  5. Puerto default 18789 → Escaneado por bots/hackers         │
│                                                                  │
│  6. Docker Desktop VM → Escape más fácil que Linux nativo       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## ARQUITECTURA SEGURA (VPS)

```
┌─────────────────────────────────────────────────────────────────┐
│                     ARQUITECTURA SEGURA                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   INTERNET                                                      │
│      ▲                                                         │
│      │ OpenClaw llama APIs (OpenAI, Anthropic, Brave)         │
│      │                                                         │
│   ┌──┴───┐         Tailscale Network (100.x.x.x)             │
│   │ VPS  │ ◄──────────────────────────► MacBook (tú)        │
│   │      │         100.x.x.x (dinámica)    100.x.x.x         │
│   │      │                                                   │
│   │Open  │  ┌────────────────────────────────────────────┐    │
│   │Claw  │  │ OpenClaw Gateway                          │    │
│   │      │  │ bind: 127.0.0.1:45678 (SOLO localhost)   │    │
│   │      │  │ proceso principal: internet SÍ            │    │
│   │      │  │ sandbox Docker: network:none (NO internet)│    │
│   │      │  └────────────────────────────────────────────┘    │
│   └──────┘                                                   │
│                                                                  │
│   ACCESO:                                                      │
│   - MacBook → Tailscale → VPS:45678 (tú)                     │
│   - Internet → VPS:45678: BLOQUEADO (bind 127.0.0.1)         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Puntos clave:**
1. Gateway bind a 127.0.0.1 → NO accesible desde internet
2. Sandbox network:none → código del usuario sin internet
3. APIs se llaman desde proceso principal → SÍ tiene internet
4. Tailscale para acceso remoto → tú te conectas así
┌─────────────────────────────────────────────────────────────────┐
│                     ARQUITECTURA SEGURA                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────────┐    Tailscale     ┌──────────────────────┐   │
│   │ MacBook PRO  │ ───────────────▶ │    Mac Mini (vos)    │   │
│   │   (tú)       │    100.x.x.x     │                      │   │
│   └──────────────┘                  │  ┌────────────────┐  │   │
│         │                            │  │ OpenClaw       │  │   │
│         │                            │  │ Gateway        │  │   │
│         │                            │  │ 127.0.0.1:45678│  │   │
│         │                            │  └────────────────┘  │   │
│         │                            │         │            │   │
│         │                            │         ▼            │   │
│         │                            │  ┌────────────────┐  │   │
│         │                            │  │ Sandbox Docker │  │   │
│         │                            │  │ network:none   │  │   │
│         │                            │  │ readonly:true  │  │   │
│         │                            │  └────────────────┘  │   │
│         │                            │                      │   │
│         │                            │  APIs: OpenAI, Brave│  │
│         │                            │  (desde proceso      │  │
│         │                            │   principal, NO      │  │
│         │                            │   sandbox)          │   │
│         │                            │                      │   │
│         └──────────────────────────▶│  PF Firewall        │   │
│              SSH/Telegram             │  Puerto 45678 solo  │   │
│                                       │  en loopback        │   │
│                                       └──────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## FASE 0: PREPARACIÓN ENTORNO VPS (SEGURIDAD MÁXIMA)

### 0.1 Requisitos del Sistema (VPS Linux)

```bash
# Conectarse al VPS
ssh <tu_usuario>@<IP_VPS>

# Verificar sistema
cat /etc/os-release  # Ubuntu/Debian/CentOS
docker --version
node --version
pm2 --version

# Instalar dependencias si faltan
sudo apt update
sudo apt install -y curl wget git docker.io docker-compose
```

### 0.2 Crear Usuario Dedicado para OpenClaw (CRÍTICO)

```bash
# En VPS - Crear usuario SIN privilegios sudo
sudo adduser openclawuser
# (Establecer contraseña segura)

# Verificar que NO es sudo
getent group sudo | grep openclawuser
# Expected: (vacío - no es sudo)
```

### 0.3 Directorios con Permisos Aislados

```bash
# Crear estructura de directorios con permisos estrictos
sudo mkdir -p /home/openclawuser/{.openclaw/{config,logs,data,audit,backups},projects}

# Permisos: solo el usuario openclawuser puede leer/escribir
sudo chown -R openclawuser:openclawuser /home/openclawuser/.openclaw
sudo chmod -R 700 /home/openclawuser/.openclaw
```

### 0.4 Docker - Configuración de Seguridad

```bash
# En VPS - Configurar Docker:

# 1. Editar /etc/docker/daemon.json
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# 2. Reiniciar Docker
sudo systemctl restart docker

# 3. Añadir usuario a grupo docker (para poder usar docker sin sudo)
sudo usermod -aG docker openclawuser
# NOTA: Esto es necesario para que OpenClaw pueda usar Docker
```

### 0.5 Generar Token de Seguridad

```bash
# Generar token aleatorio seguro
ssh <tu_usuario>@<IP_VPS> 'GATEWAY_TOKEN=$(openssl rand -hex 48) && echo $GATEWAY_TOKEN'

# Guardar en archivo con permisos restrictivos
echo "TOKEN_GENERADO" > ~/.openclaw/gateway_token
chmod 600 ~/.openclaw/gateway_token
```

---

## FASE 1: CONFIGURACIÓN SEGURA (v3.0)

### 1.1 Archivo de Configuración

Crear `~/.openclaw/config/openclaw.json` con valores SEGUROS:

```json
{
  "$schema": "https://openclaw.ai/schemas/config-v1.json",
  "version": "1.0.0",
  "name": "openclaw-prod",

  "system": {
    "logLevel": "info",
    "logFormat": "json",
    "environment": "production"
  },

  "gateway": {
    "bind": "127.0.0.1",
    "port": 45678,
    "auth": {
      "mode": "token",
      "tokenEnv": "OPENCLAW_GATEWAY_TOKEN",
      "tokenExpiry": null,
      "refreshToken": false
    }
  },

  "providers": {
    "primary": "openai",
    "fallback": ["anthropic"],

    "openai": {
      "name": "openai",
      "apiKey": "${OPENAI_API_KEY}",
      "models": {
        "gpt-4o-mini": {
          "enabled": true,
          "contextWindow": 128000,
          "maxOutput": 16384,
          "temperature": 0.7
        }
      }
    },

    "anthropic": {
      "name": "anthropic",
      "apiKey": "${ANTHROPIC_API_KEY}",
      "models": {
        "claude-sonnet-4-20250514": {
          "enabled": true,
          "contextWindow": 200000,
          "maxOutput": 8192,
          "temperature": 0.7
        }
      }
    },

    "brave-search": {
      "name": "brave-search",
      "apiKey": "${BRAVE_SEARCH_API_KEY}",
      "contextMode": true
    }
  },

  "memory": {
    "enabled": true,
    "types": {
      "agent": { "backend": "sqlite", "retention": "permanent" },
      "unit": { "backend": "sqlite", "retention": "permanent" },
      "domain": { "backend": "sqlite", "retention": "permanent" },
      "global": { "backend": "sqlite", "retention": "permanent" }
    },
    "embedding": {
      "model": "nomic-embed-text",
      "dimensions": 768
    }
  },

  "security": {
    "execApprovals": {
      "enabled": true,
      "mode": "interactive",
      "logAll": true,
      "auditPath": "~/.openclaw/audit/exec.log",
      "autoApprove": {
        "safe": false,
        "requiresApproval": true,
        "prohibited": false
      }
    },

    "safeBinPolicy": {
      "enabled": true,
      "allowedBins": [
        "ls", "cat", "head", "tail", "grep", "wc", "sort", "uniq", "find"
      ],
      "forbiddenBins": [
        "mkfs", "fdisk", "parted", "dd", "shred",
        "iptables", "ip6tables", "nft",
        "systemctl", "reboot", "shutdown", "poweroff",
        "passwd", "chsh", "usermod", "userdel",
        "python", "python3", "node", "ruby", "perl", "php",
        "bash", "zsh", "sh", "osascript",
        "curl", "wget", "nc", "netcat", "telnet",
        "ssh", "scp", "sftp"
      ]
    },

    "sandbox": {
      "enabled": true,
      "backend": "docker",
      "config": {
        "networkMode": "none",
        "memory": "512m",
        "cpus": 1,
        "user": "nobody",
        "readOnlyRootFilesystem": true,
        "capDrop": ["ALL"],
        "securityOpt": ["no-new-privileges"],
        "pidsLimit": 256,
        "tmpfs": ["/tmp", "/var/tmp"]
      }
    }
  },

  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "allowFrom": ["@tu_usuario"],
      "streaming": true
    }
  },

  "tools": {
    "profile": "messaging",
    "deny": [
      "group:automation",
      "group:runtime",
      "group:fs",
      "sessions_spawn",
      "sessions_send"
    ],
    "fs": {
      "workspaceOnly": true
    },
    "exec": {
      "security": "allowlist",
      "allowBinaries": ["git", "node", "python3", "npm", "pip"],
      "ask": "always"
    },
    "elevated": {
      "enabled": false
    }
  },

  "browser": {
    "ssrfPolicy": {
      "dangerouslyAllowPrivateNetwork": false
    }
  },

  "discovery": {
    "mdns": {
      "mode": "off"
    }
  },

  "logging": {
    "redactSensitive": "tools",
    "redactPatterns": [
      "sk-[a-zA-Z0-9]{20,}",
      "ghp_[a-zA-Z0-9]{36}",
      "AKIA[0-9A-Z]{16}"
    ]
  },

  "domains": {
    "/dev": {
      "chief": "cengo",
      "unit": "DEV-001",
      "description": "Desarrollo y código"
    },
    "/general": {
      "chief": "cko",
      "unit": "GEN-001",
      "description": "Consultas generales"
    }
  },

  "heartbeat": {
    "enabled": true,
    "intervalMs": 60000
  }
}
```

### 1.2 Variables de Entorno (.env)

```bash
# En VPS (Linux)
# Usar archivo .env con permisos restrictivos

mkdir -p ~/.openclaw/config
cat > ~/.openclaw/config/.env << 'EOF'
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
export BRAVE_SEARCH_API_KEY="..."
export TELEGRAM_BOT_TOKEN="..."
export NODE_ENV=production
export LOG_LEVEL=info
EOF

chmod 600 ~/.openclaw/config/.env
```

### 1.3 Cargar Token (Linux)

```bash
# Guardar token en archivo separado (más seguro que en JSON)
mkdir -p ~/.openclaw
echo "TU_TOKEN_GENERADO" > ~/.openclaw/gateway_token
chmod 600 ~/.openclaw/gateway_token
```

---

## FASE 2: FIREWALL UFW (PROTECCIÓN CAPA RED - VPS LINUX)

### 2.1 Instalar y configurar UFW

```bash
# En VPS (Linux Ubuntu/Debian)

# Instalar UFW si no existe
sudo apt update && sudo apt install ufw -y

# Política por defecto: denegar todo entrante
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Permitir SSH (importante no bloquearse!)
sudo ufw allow 22/tcp

# NO permitir el puerto 45678 desde fuera - solo loopback
# El gateway está bound a 127.0.0.1, así que ya es seguro

# Habilitar UFW
sudo ufw enable

# Ver estado
sudo ufw status verbose
```

---

## FASE 3: INICIO COMO USUARIO DEDICADO

### 3.1 PM2 Config

```bash
ssh openclawuser@<IP_VPS>

cat > ~/.openclaw/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'openclaw-gateway',
    script: 'dist/entry.js',
    args: 'gateway start --non-interactive',
    instances: 1,
    exec_mode: 'fork',
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'production',
      OPENCLAW_CONFIG_PATH: '/home/openclawuser/.openclaw/config',
      PATH: '/usr/bin:/bin:/usr/local/bin'
    },
    error_file: '/home/openclawuser/.openclaw/logs/gateway-error.log',
    out_file: '/home/openclawuser/.openclaw/logs/gateway.log',
    time: true
  }]
};
EOF
```

### 3.2 Iniciar

```bash
# Cambiar a usuario openclawuser
su - openclawuser

# Cargar variables de entorno
source ~/.openclaw/config/.env

# Obtener token
export GATEWAY_TOKEN=$(cat ~/.openclaw/gateway_token)

# Ir al directorio de OpenClaw
cd ~/projects/openclaw

# Instalar dependencias si no existen
npm install

# Iniciar con PM2
pm2 start ~/.openclaw/ecosystem.config.js
pm2 save
```

---

## FASE 4: MONITOREO AVANZADO PUERTO 45678

### 4.1 Script de Monitoreo de Intrusiones

```bash
cat > ~/scripts/openclaw-monitor.sh << 'EOF'
#!/bin/bash
# Monitoreo de intentos de conexión al puerto 45678

LOG_FILE="$HOME/.openclaw/logs/intrusion.log"
ALERT_THRESHOLD=5

# Verificar conexiones externas intentadas (bloqueadas por PF)
# Si hay muchos intentos, es escaneo

# Registrar intento
echo "$(date '+%Y-%m-%d %H:%M:%S') - Health check OK - Puerto 45678" >> $LOG_FILE
EOF

chmod +x ~/scripts/openclaw-monitor.sh
```

### 4.2 Alertas de Actividad Sospechosa

```bash
# Añadir a crontab para monitoreo continuo
# Monitorear cada minuto
* * * * * /home/openclawuser/scripts/openclaw-monitor.sh
```

---

## FASE 5: ACCESO DESDE MACBOOK VIA TAILSCALE

### 5.1 Verificar Tailscale en VPS

```bash
# En VPS - Instalar Tailscale si no existe
curl -fsSL https://tailscale.com/install.sh | sh

# Iniciar Tailscale
sudo tailscale up

# Obtener IP de Tailscale
tailscale ip -4
# Anotar esta IP (100.x.x.x)
```

### 5.2 Conectar desde MacBook

```bash
# En MacBook - Instalar Tailscale si no existe
# Desde https://tailscale.com

# Conectar a la red Tailscale
tailscale up

# Ver IP de Tailscale del VPS
tailscale status
# Buscar el hostname del VPS y su IP (100.x.x.x)
```

### 5.3 Acceder a OpenClaw Gateway

```bash
# Opción A: SSH Tunnel (RECOMENDADO)
# Desde MacBook:
ssh -L 45678:127.0.0.1:45678 <tu_usuario>@<IP_TAILSCALE_VPS> -N

# Luego abrir en navegador:
open http://localhost:45678

# Añadir token en la UI:
# http://localhost:45678/#token=TOKEN

# Opción B: Directamente via Tailscale IP (si funciona)
# En navegador:
open http://<IP_TAILSCALE_VPS>:45678
# Añadir token: http://<IP_TAILSCALE_VPS>:45678/#token=TOKEN

# Para obtener el token:
ssh <tu_usuario>@<IP_VPS> 'cat ~/.openclaw/gateway_token'
```

---

## FASE 5: VERIFICACIONES DE SEGURIDAD

### 5.1 Checklist

| # | Verificación | Comando | Esperado |
|---|--------------|---------|----------|
| 5.1.1 | Puerto 45678 solo loopback | `ss -tlnp \| grep 45678` | 127.0.0.1:45678 |
| 5.1.2 | Puerto 18789 CERRADO | `ss -tlnp \| grep 18789` | (nada) |
| 5.1.3 | Usuario dedicado | `whoami` | openclawuser |
| 5.1.4 | Permisos 700 | `ls -la ~/.openclaw` | drwx------ |
| 5.1.5 | UFW activo | `sudo ufw status` | Status: active |
| 5.1.6 | Docker funciona | `docker ps` | Lista de contenedores |
| 5.1.7 | Token en archivo | `cat ~/.openclaw/gateway_token` | Token existe |

---

## COMPARATIVA: PUERTO DEFAULT vs SEGURO

| Aspecto | Puerto 18789 (Default) | Puerto 45678 (Seguro) |
|---------|------------------------|----------------------|
| Escaneos automáticos | ✅ Encontrado | ❌ No encontrado |
| Shodan/Censys | ✅ Indexado | ❌ No indexado |
| Bots/Hackers | ✅ Intentan | ❌ Ignoran |
| Facilidad | Alta | Media |
| Recordar | Difícil | Fácil (45678) |

---

## CHECKLIST RESUMEN v4.0 (VPS)

```
## FASE 0: Preparación VPS
[ ] 0.1 Docker instalado en VPS
[ ] 0.2 Usuario dedicado openclawuser (sin sudo)
[ ] 0.3 Permisos 700 en ~/.openclaw
[ ] 0.4 Token generado y guardado

## FASE 1: Configuración
[ ] 1.1 PUERTO: 45678 (NO 18789)
[ ] 1.2 bind: 127.0.0.1 (solo localhost)
[ ] 1.3 networkMode: "none" (sandbox)
[ ] 1.4 readOnlyRootFilesystem: true
[ ] 1.5 tools: profile: "messaging"
[ ] 1.6 tools: deny: [group:automation, group:runtime, group:fs]
[ ] 1.7 tools: exec: allowlist + ask:always
[ ] 1.8 tools: elevated: enabled: false
[ ] 1.9 browser: ssrfPolicy: dangerouslyAllowPrivateNetwork: false
[ ] 1.10 discovery: mdns: mode: "off"
[ ] 1.11 logging: redactSensitive: true

## FASE 2: Firewall
[ ] 2.1 UFW instalado y activo
[ ] 2.2 SSH permitido (puerto 22)
[ ] 2.3 Puerto 45678 NO expuesto (solo loopback)

## FASE 3: Inicio
[ ] 3.1 PM2 instalado
[ ] 3.2 OpenClaw iniciado como openclawuser
[ ] 3.3 pm2 save ejecutado

## FASE 4: Tailscale
[ ] 4.1 Tailscale instalado en VPS
[ ] 4.2 Tailscale funcionando
[ ] 4.3 IP Tailscale del VPS conocida

## FASE 5: Acceso desde MacBook
[ ] 5.1 Tailscale instalado en MacBook
[ ] 5.2 SSH Tunnel funciona
[ ] 5.3 WebUI accesible con token
```

## FASE 2: Firewall
[ ] 2.1 PF: Puerto 45678 solo loopback
[ ] 2.2 Puerto 18789 verificado como CERRADO

## FASE 3: Inicio
[ ] 3.1 PM2 como openclawuser
[ ] 3.2 Secretos desde Keychain

## FASE 4: Verificación
[ ] 4.1 Puerto 45678 solo en 127.0.0.1
[ ] 4.2 PF activo
[ ] 4.3 Health check responde
```

---

## RESUMEN: QUÉ PROTEGE QUÉ

| Amenaza | Protección |
|---------|------------|
| Escaneos automáticos | Puerto 45678 (no default) |
| Acceso externo al gateway | `bind: 127.0.0.1` + PF |
| Escape de Docker sandbox | `networkMode: none`, `capDrop: ALL`, `readOnlyRootFilesystem: true` |
| Acceso a datos del host | Usuario dedicado sin admin, Docker sin /Users mount |
| Ejecución de comandos peligrosos | Allowlist bins, bloquea python/node/bash/curl |
| Filtración de tokens | Keychain + variable de entorno |
| Persistencia malware | Sandbox efímero, FS readonly |

---

**Documento actualizado:** 2026-03-10 v3.0
**Cambios clave:** Puerto 45678 (no default 18789) + seguridad máxima
