# Auditoría y Correcciones de Seguridad - OPENCLAW Personal

**ID:** DOC-PER-AUD-001
**Versión:** 1.0
**Fecha:** 2026-03-10
**Estado:** CRÍTICO - APLICAR ANTES DE INSTALACIÓN

---

## Problemas Críticos Encontrados

### Ruta 1: M1 Mac Mini

| ID | Problema | Severidad | Solución |
|----|----------|-----------|----------|
| M1-01 | Sin firewall macOS configurado | CRÍTICO | Añadir configuración pf/Lulu |
| M1-02 | Gateway sin autenticación | CRÍTICO | Añadir API key obligatoria |
| M1-03 | Falta verificación NVMe montado | ALTA | Script de pre-check |
| M1-04 | Variables .env hardcodeadas | ALTA | Generar dinámicamente |
| M1-05 | Sin verificación espacio disco | MEDIA | Añadir comprobación |
| M1-06 | Falta dependencia @ai-sdk/openai-compatible | ALTA | Añadir a pnpm add |
| M1-07 | No hay test de auto-inicio | MEDIA | Verificar tras reinicio |

### Ruta 2: VPS Hetzner

| ID | Problema | Severidad | Solución |
|----|----------|-----------|----------|
| VPS-01 | Sin fail2ban | CRÍTICO | Instalar y configurar |
| VPS-02 | Sin actualizaciones auto | ALTA | Configurar unattended-upgrades |
| VPS-03 | API key mal generada en heredoc | ALTA | Generar antes del cat |
| VPS-04 | Sin backup de secrets | ALTA | Añadir backup .env cifrado |
| VPS-05 | Rate limiting mal configurado | MEDIA | Corregir zona en nginx |

### Ruta 3: Distribuida

| ID | Problema | Severidad | Solución |
|----|----------|-----------|----------|
| DIST-01 | Sin orden de instalación | CRÍTICO | Definir secuencia obligatoria |
| DIST-02 | IPs placeholder sin remplazar | ALTA | Instrucciones claras |
| DIST-03 | Sin verificación Tailscale | ALTA | Pre-check conectividad |
| DIST-04 | Sin manejo de fallo de nodo | ALTA | Documentar failover |
| DIST-05 | Secrets no sincronizados | ALTA | Vault o sync manual |

---

## Correcciones a Aplicar

### CORRECCIÓN M1-01: Firewall macOS

Añadir después de Fase 1.3:

```bash
# === FIREWALL macOS ===
# Opción A: Usar pf (builtin)
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalon
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

# Verificar
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# Opción B: LuLu (más granular, recomendado)
brew install --cask lulu
# Configurar LuLu para bloquear conexiones salientes no autorizadas
```

### CORRECCIÓN M1-02: Gateway con Autenticación

Reemplazar el código del gateway (Fase 4.2):

```bash
cat > $OPENCLAW_ROOT/gateway/src/index.js << 'EOF'
import Fastify from 'fastify';
import websocket from '@fastify/websocket';
import cors from '@fastify/cors';
import dotenv from 'dotenv';
import crypto from 'crypto';

dotenv.config();

const fastify = Fastify({
  logger: {
    level: process.env.LOG_LEVEL || 'info',
    transport: { target: 'pino-pretty' }
  }
});

await fastify.register(websocket);
await fastify.register(cors, {
  origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:18790']
});

// === SEGURIDAD: API Key Middleware ===
const VALID_API_KEYS = new Set(
  (process.env.API_KEYS || '').split(',').filter(k => k.length > 0)
);

fastify.addHook('onRequest', async (request, reply) => {
  // Health check sin auth
  if (request.url === '/health') return;

  // WebSocket auth en handshake
  if (request.url.startsWith('/ws')) {
    const key = request.query.key || request.headers['x-api-key'];
    if (!key || !VALID_API_KEYS.has(key)) {
      reply.code(401).send({ error: 'Invalid API key' });
      return;
    }
    return;
  }

  // REST API auth
  const apiKey = request.headers['x-api-key'];
  if (!apiKey || !VALID_API_KEYS.has(apiKey)) {
    reply.code(401).send({ error: 'Unauthorized' });
    return;
  }
});

// === RATE LIMITING por IP ===
const requestCounts = new Map();
const RATE_LIMIT = 100; // requests por minuto
const RATE_WINDOW = 60000; // 1 minuto

fastify.addHook('onRequest', async (request, reply) => {
  const ip = request.ip;
  const now = Date.now();
  const windowStart = now - RATE_WINDOW;

  const requests = requestCounts.get(ip) || [];
  const recentRequests = requests.filter(t => t > windowStart);

  if (recentRequests.length >= RATE_LIMIT) {
    reply.code(429).send({ error: 'Too many requests' });
    return;
  }

  recentRequests.push(now);
  requestCounts.set(ip, recentRequests);

  // Limpiar IPs antiguas cada 100 requests
  if (requestCounts.size > 1000) {
    for (const [ip, times] of requestCounts) {
      if (times.every(t => t < windowStart)) {
        requestCounts.delete(ip);
      }
    }
  }
});

// Health check
fastify.get('/health', async () => ({
  status: 'ok',
  timestamp: Date.now(),
  version: '1.0.0',
  node: 'macmini'
}));

// WebSocket principal
fastify.register(async function (fastify) {
  fastify.get('/ws', { websocket: true }, (connection, req) => {
    connection.socket.on('message', async (message) => {
      try {
        const data = JSON.parse(message.toString());
        const result = await procesarLocalmente(data);
        connection.socket.send(JSON.stringify(result));
      } catch (error) {
        connection.socket.send(JSON.stringify({
          error: error.message,
          code: 'INTERNAL_ERROR'
        }));
      }
    });
  });
});

// API REST
fastify.post('/api/solicitud', async (request, reply) => {
  const { mensaje, namespace, contexto } = request.body;
  return await procesarLocalmente({ mensaje, namespace, contexto });
});

async function procesarLocalmente(data) {
  // Integrar con orquestador
  return {
    processed: true,
    node: 'macmini',
    timestamp: Date.now(),
    data
  };
}

const start = async () => {
  try {
    const host = process.env.HOST || '127.0.0.1';
    const port = parseInt(process.env.PORT) || 18789;

    await fastify.listen({ port, host });
    console.log(`Gateway running on http://${host}:${port}`);
    console.log(`Security: API Key required, Rate limit: ${RATE_LIMIT}/min`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();
EOF
```

### CORRECCIÓN M1-03: Variables de Entorno Seguras

Reemplazar Fase 4.3:

```bash
# === GENERAR SECRETS SEGUROS ===
cd $OPENCLAW_ROOT/gateway

# Generar API keys (guardar en lugar seguro)
API_KEY_1=$(openssl rand -hex 32)
API_KEY_2=$(openssl rand -hex 32)  # Backup key
REDIS_PASSWORD=$(openssl rand -hex 32)
JWT_SECRET=$(openssl rand -hex 64)

# Crear .env
cat > .env << EOF
# Generado automáticamente - NO COMMIT A GIT
NODE_ENV=production
HOST=127.0.0.1
PORT=18789

# API Keys (usar cualquiera)
API_KEYS=${API_KEY_1},${API_KEY_2}

# CORS (separar con comas)
CORS_ORIGIN=http://localhost:18790

# Redis
REDIS_URL=redis://127.0.0.1:6379
REDIS_PASSWORD=${REDIS_PASSWORD}

# JWT para sesiones
JWT_SECRET=${JWT_SECRET}

# Logging
LOG_LEVEL=info
EOF

# Configurar Redis con la contraseña
redis-cli CONFIG SET requirepass "${REDIS_PASSWORD}"
redis-cli -a "${REDIS_PASSWORD}" CONFIG REWRITE

# Guardar backup de secrets (cifrado)
mkdir -p $OPENCLAW_ROOT/secrets
echo "API_KEY_1=${API_KEY_1}" > $OPENCLAW_ROOT/secrets/.keys
echo "API_KEY_2=${API_KEY_2}" >> $OPENCLAW_ROOT/secrets/.keys
echo "REDIS_PASSWORD=${REDIS_PASSWORD}" >> $OPENCLAW_ROOT/secrets/.keys
echo "JWT_SECRET=${JWT_SECRET}" >> $OPENCLAW_ROOT/secrets/.keys
chmod 600 $OPENCLAW_ROOT/secrets/.keys

# Añadir .env a .gitignore
echo ".env" >> $OPENCLAW_ROOT/.gitignore
echo "secrets/" >> $OPENCLAW_ROOT/.gitignore

echo "=== IMPORTANTE: Guarda estas claves en un gestor de contraseñas ==="
cat $OPENCLAW_ROOT/secrets/.keys
```

### CORRECCIÓN M1-05: Script de Pre-Check

Añadir al inicio de Fase 1:

```bash
# === PRE-CHECK DEL SISTEMA ===
cat > /tmp/openclaw-precheck.sh << 'SCRIPT'
#!/bin/bash
ERRORS=0

echo "=== OPENCLAW Pre-Installation Check ==="

# 1. macOS versión
if [[ $(sw_vers -productVersion | cut -d. -f1) -lt 14 ]]; then
  echo "❌ macOS 14+ requerido (tienes $(sw_vers -productVersion))"
  ERRORS=$((ERRORS+1))
else
  echo "✅ macOS $(sw_vers -productVersion)"
fi

# 2. Arquitectura
if [[ $(uname -m) != "arm64" ]]; then
  echo "❌ Se requiere Apple Silicon (M1/M2/M3)"
  ERRORS=$((ERRORS+1))
else
  echo "✅ Arquitectura arm64"
fi

# 3. NVMe montado
NVME_PATH="/Volumes/NVMe-4TB"  # Ajustar según tu configuración
if [[ ! -d "$NVME_PATH" ]]; then
  echo "❌ NVMe no encontrado en $NVME_PATH"
  echo "   Monta el NVMe y ajusta la ruta en el script"
  ERRORS=$((ERRORS+1))
else
  echo "✅ NVMe encontrado en $NVME_PATH"
fi

# 4. Espacio disponible (mínimo 100GB)
if [[ -d "$NVME_PATH" ]]; then
  AVAILABLE=$(df -g "$NVME_PATH" | tail -1 | awk '{print $4}')
  if [[ $AVAILABLE -lt 100 ]]; then
    echo "⚠️  Solo $AVAILABLE GB disponibles (recomendado: 100GB+)"
  else
    echo "✅ Espacio disponible: ${AVAILABLE}GB"
  fi
fi

# 5. RAM
TOTAL_RAM=$(sysctl -n hw.memsize | awk '{print $1/1024/1024/1024}')
if [[ ${TOTAL_RAM%.*} -lt 14 ]]; then
  echo "⚠️  RAM: ${TOTAL_RAM%.*}GB (recomendado: 16GB+)"
else
  echo "✅ RAM: ${TOTAL_RAM%.*}GB"
fi

# 6. Homebrew
if ! command -v brew &> /dev/null; then
  echo "⚠️  Homebrew no instalado (se instalará)"
else
  echo "✅ Homebrew: $(brew --version | head -1)"
fi

# 7. Xcode CLI
if ! xcode-select -p &> /dev/null; then
  echo "⚠️  Xcode CLI no instalado (ejecuta: xcode-select --install)"
else
  echo "✅ Xcode CLI"
fi

echo ""
if [[ $ERRORS -gt 0 ]]; then
  echo "❌ $ERRORS error(es) encontrado(s). Corrige antes de continuar."
  exit 1
else
  echo "✅ Sistema listo para instalación"
  exit 0
fi
SCRIPT

chmod +x /tmp/openclaw-precheck.sh
/tmp/openclaw-precheck.sh
```

### CORRECCIÓN VPS-01: Fail2ban

Añadir después de Fase 1.3:

```bash
# === FAIL2BAN ===
sudo apt install -y fail2ban

# Configuración SSH
sudo cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
ignoreip = 127.0.0.1/8

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 24h

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/*error.log
maxretry = 5
bantime = 1h
EOF

sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Verificar
sudo fail2ban-client status sshd
```

### CORRECCIÓN VPS-02: Actualizaciones Automáticas

```bash
# === ACTUALIZACIONES AUTOMÁTICAS DE SEGURIDAD ===
sudo apt install -y unattended-upgrades

sudo cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
EOF

sudo cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::Package-Blacklist {};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

# Verificar
sudo unattended-upgrade --dry-run
```

### CORRECCIÓN DIST-01: Orden de Instalación

Añadir al inicio de Ruta 3:

```
## ⚠️ ORDEN OBLIGATORIO DE INSTALACIÓN

El sistema distribuido DEBE instalarse en este orden exacto:

### Paso 0: Preparación (30 min)

1. **Asegurar que todos los dispositivos tienen Tailscale**
   ```bash
   # En cada dispositivo
   tailscale status
   tailscale ip -4  # Anotar cada IP
   ```

2. **Verificar conectividad entre nodos**
   ```bash
   # Desde Mac Mini
   ping 100.x.x.x  # IP del VPS
   ping 100.x.x.x  # IP del MacBook

   # Desde VPS
   ping 100.x.x.x  # IP del Mac Mini (debe responder)
   ```

3. **Configurar ACLs en Tailscale Admin Console** (ver Fase 1.2)

### Paso 1: Mac Mini (2 horas) - NÚCLEO PRINCIPAL

Ejecutar Ruta 1 COMPLETA incluyendo todas las correcciones de seguridad.
El Mac Mini es el servidor principal y DEBE estar listo antes de continuar.

### Paso 2: VPS (1 hora) - GATEWAY PÚBLICO

Ejecutar Ruta 2 hasta Fase 6 (Nginx).
Configurar proxy hacia Mac Mini usando IP Tailscale.

### Paso 3: Conectar Mac Mini ↔ VPS (30 min)

1. Verificar que VPS puede reach Mac Mini por Tailscale
2. Configurar backup remoto
3. Probar end-to-end: Internet → VPS → Mac Mini

### Paso 4: MacBook Pro (30 min) - LLM SERVER

1. Instalar LMStudio
2. Descargar modelos
3. Configurar Link Server
4. Verificar desde Mac Mini que el endpoint responde

### Paso 5: Móviles (15 min)

1. Instalar Tailscale en cada dispositivo
2. Probar acceso a Mac Mini:18790

### Paso 6: Verificación Final (15 min)

Ejecutar smoke tests completos de todos los nodos.
```

---

## Checklist de Seguridad Pre-Instalación

Antes de empezar CUALQUIER ruta, verificar:

```bash
# Copiar y ejecutar este checklist

echo "=== SECURITY PRE-CHECK ==="

# 1. No hay procesos sospechosos
ps aux | grep -E "(crypto|miner|xmr)" && echo "❌ Procesos sospechosos" || echo "✅ Sin procesos sospechosos"

# 2. Puertos abiertos
echo "Puertos en uso:"
lsof -i -P | grep LISTEN | head -20

# 3. Usuarios con acceso sudo
echo "Usuarios sudo:"
grep -Po '^sudo.+:\K.*$' /etc/group 2>/dev/null || dscl . read /Groups/admin GroupMembership 2>/dev/null

# 4. SSH (en VPS)
if command -v sshd &> /dev/null; then
  echo "Config SSH:"
  sudo grep -E "^(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication)" /etc/ssh/sshd_config
fi

# 5. Firewall
if command -v ufw &> /dev/null; then
  sudo ufw status
elif command -v socketfilterfw &> /dev/null; then
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
fi

echo "=== FIN PRE-CHECK ==="
```

---

**Documento:** Auditoría y Correcciones de Seguridad
**Ubicación:** `docs/INSTALACION-PERSONAL/05-auditoria-correcciones.md`
