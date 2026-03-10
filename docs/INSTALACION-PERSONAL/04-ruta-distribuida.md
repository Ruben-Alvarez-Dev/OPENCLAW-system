# Ruta de Instalación: Sistema Distribuido M1 + VPS

**ID:** DOC-PER-INS-003
**Versión:** 1.0
**Fecha:** 2026-03-10
**Arquitectura:** Distribuida Multi-Nodo

---

## Resumen

Instalación distribuida de OPENCLAW-system aprovechando todo el ecosistema:
- **Mac Mini M1**: Servidor principal local (24/7)
- **VPS Hetzner**: Gateway público + backup
- **MacBook Pro M1 Max**: LLM Server bajo demanda
- **Dispositivos móviles**: Clientes

**Tiempo estimado:** 5-6 horas
**Dificultad:** Alta

---

## Arquitectura Distribuida

```
                    ┌─────────────────────────────────────┐
                    │         INTERNET                    │
                    └─────────────────────────────────────┘
                                      │
                    ┌─────────────────▼─────────────────┐
                    │     VPS HETZNER (Gateway)         │
                    │  - Nginx proxy inverso            │
                    │  - API pública                    │
                    │  - Backup location                │
                    │  - Cloud agents                   │
                    │  Puerto: 80/443                   │
                    └─────────────────┬─────────────────┘
                                      │
                              Tailscale VPN
                                      │
        ┌─────────────────────────────┼─────────────────────────────┐
        │                             │                             │
┌───────▼───────┐           ┌─────────▼─────────┐         ┌────────▼────────┐
│  MAC MINI M1  │           │  MACBOOK PRO M1   │         │   MÓVILES       │
│  (Core)       │◄─────────►│  MAX (LLM Server) │         │   (Clientes)    │
│               │  Tailscale│                   │         │                 │
│ - Gateway     │           │ - LMStudio Link   │         │ - S9 FE+        │
│ - Orquestador │           │ - Ollama large    │         │ - Xiaomi Pad 5  │
│ - Redis       │           │ - Modelos 13-70B  │         │ - Pixel XL 10   │
│ - Ollama 3-7B │           │                   │         │ - Xiaomi Note   │
│ - Mission Ctrl│           │ (Solo cuando      │         │                 │
│ - Memoria     │           │  encendido)       │         │ Acceso via      │
│               │           │                   │         │ Tailscale       │
│ Puerto:       │           │ Puerto:           │         │                 │
│ 18789,18790   │           │ 1234,11434        │         │                 │
└───────────────┘           └───────────────────┘         └─────────────────┘
        │
        │ NVMe 4TB
        ▼
┌─────────────────┐
│   ALMACENAMIENTO│
│   - Vector DB   │
│   - Conocimiento│
│   - Backups     │
└─────────────────┘
```

---

## Fase 1: Configuración de Red (Tailscale)

### 1.1 Obtener IPs Tailscale

**En cada dispositivo:**

```bash
# Mac Mini
tailscale ip -4  # 100.x.x.x (anotar como MACMINI_IP)

# MacBook Pro
tailscale ip -4  # 100.x.x.x (anotar como MBP_IP)

# VPS
tailscale ip -4  # 100.x.x.x (anotar como VPS_IP)
```

### 1.2 ACLs Tailscale

Crear archivo de configuración en Tailscale Admin Console:

```json
{
  "acls": [
    // VPS puede recibir conexiones pero no iniciar hacia otros
    {
      "action": "accept",
      "src": ["tag:vps"],
      "dst": ["tag:vps:*"]
    },
    // Mac Mini y MBP pueden comunicarse
    {
      "action": "accept",
      "src": ["tag:server", "tag:workstation"],
      "dst": ["tag:server:*", "tag:workstation:*"]
    },
    // Móviles pueden conectarse a Mac Mini
    {
      "action": "accept",
      "src": ["tag:mobile"],
      "dst": ["tag:server:18789", "tag:server:18790"]
    }
  ],
  "tagOwners": {
    "tag:server": ["autogroup:admin"],
    "tag:workstation": ["autogroup:admin"],
    "tag:mobile": ["autogroup:admin"],
    "tag:vps": ["autogroup:admin"]
  }
}
```

### 1.3 Configurar Tags

En Tailscale Admin Console:
- Mac Mini → `tag:server`
- MacBook Pro → `tag:workstation`
- VPS → `tag:vps`
- Móviles → `tag:mobile`

---

## Fase 2: Mac Mini M1 (Nodo Principal)

### 2.1 Estructura de Directorios

```bash
export OPENCLAW_ROOT="/Volumes/NVMe-4TB/openclaw"

mkdir -p $OPENCLAW_ROOT/{gateway,orquestador,catedraticos,especialistas,memoria,conocimiento,logs,mission-control,backups,config}

# Config distribuida
mkdir -p $OPENCLAW_ROOT/config/distributed
```

### 2.2 Configuración Distribuida

```bash
cat > $OPENCLAW_ROOT/config/distributed/nodes.json << 'EOF'
{
  "nodes": {
    "macmini": {
      "role": "core",
      "tailscale_ip": "100.x.x.x",
      "services": ["gateway", "orquestador", "redis", "ollama-small", "mission-control"],
      "ports": {
        "gateway": 18789,
        "mission_control": 18790,
        "ollama": 11434,
        "redis": 6379
      },
      "models": ["llama3.2:3b", "qwen2.5:7b", "nomic-embed-text"],
      "storage": "/Volumes/NVMe-4TB/openclaw"
    },
    "macbook": {
      "role": "llm-server",
      "tailscale_ip": "100.x.x.x",
      "services": ["lmstudio-link", "ollama-large"],
      "ports": {
        "lmstudio": 1234,
        "ollama": 11434
      },
      "models": ["llama3.1:70b-q4", "mixtral:8x7b-q4", "codestral:22b"],
      "availability": "on-demand"
    },
    "vps": {
      "role": "gateway-public",
      "public_ip": "TU_IP_PUBLICA",
      "tailscale_ip": "100.x.x.x",
      "services": ["nginx-proxy", "api-public", "backup"],
      "ports": {
        "http": 80,
        "https": 443
      }
    }
  },
  "routing": {
    "default": "macmini",
    "llm_large": "macbook",
    "public": "vps"
  }
}
EOF
```

### 2.3 Gateway con Routing Distribuido

```bash
cat > $OPENCLAW_ROOT/gateway/src/index.js << 'EOF'
import Fastify from 'fastify';
import websocket from '@fastify/websocket';
import cors from '@fastify/cors';
import { nodes, routing } from './config/distributed/nodes.json';

const fastify = Fastify({ logger: true });

await fastify.register(websocket);
await fastify.register(cors);

// Detector de disponibilidad MacBook
async function isMacBookAvailable() {
  try {
    const response = await fetch(`http://${nodes.macbook.tailscale_ip}:1234/v1/models`, {
      timeout: 2000
    });
    return response.ok;
  } catch {
    return false;
  }
}

// Router inteligente de modelos
async function selectModelProvider(modelSize) {
  if (modelSize === 'large' && await isMacBookAvailable()) {
    return {
      provider: 'lmstudio',
      endpoint: `http://${nodes.macbook.tailscale_ip}:1234/v1`,
      available: true
    };
  }

  // Fallback a Mac Mini
  return {
    provider: 'ollama',
    endpoint: `http://127.0.0.1:11434`,
    available: true
  };
}

// Health check
fastify.get('/health', async () => ({
  status: 'ok',
  node: 'macmini',
  timestamp: Date.now(),
  nodes: {
    macmini: 'online',
    macbook: await isMacBookAvailable() ? 'online' : 'offline',
    vps: 'unknown'  // El VPS se reporta a sí mismo
  }
}));

// API de estado del cluster
fastify.get('/api/cluster/status', async () => {
  return {
    nodes: Object.entries(nodes).map(([name, config]) => ({
      name,
      role: config.role,
      available: name === 'macmini' || (name === 'macbook' && await isMacBookAvailable())
    }))
  };
});

// WebSocket con routing
fastify.register(async function (fastify) {
  fastify.get('/ws', { websocket: true }, (connection, req) => {
    connection.socket.on('message', async (message) => {
      const data = JSON.parse(message.toString());

      // Detectar si necesita modelo grande
      const needsLargeModel = data.complejidad === 'alta' || data.modelo?.includes('70b');

      if (needsLargeModel) {
        const provider = await selectModelProvider('large');
        if (provider.available) {
          // Route hacia MacBook
          connection.socket.send(JSON.stringify({
            routed: true,
            target: 'macbook',
            endpoint: provider.endpoint
          }));
          return;
        }
      }

      // Procesar localmente
      const result = await procesarLocalmente(data);
      connection.socket.send(JSON.stringify(result));
    });
  });
});

async function procesarLocalmente(data) {
  // Integrar con orquestador local
  return { processed: true, node: 'macmini', data };
}

const start = async () => {
  await fastify.listen({ port: 18789, host: '0.0.0.0' }); // Escuchar en todas las interfaces
  console.log('Gateway distribuido en http://0.0.0.0:18789');
};

start();
EOF
```

### 2.4 Ollama para acceso remoto

> ⚠️ **ADVERTENCIA DE SEGURIDAD:** `0.0.0.0` expone el servicio a TODAS las interfaces de red.
> **Esto es SOLO seguro si:**
> 1. El firewall bloquea puertos 11434 y 18789 desde internet
> 2. Solo se accede via red Tailscale (100.x.x.x)
> 3. El router NO tiene port forwarding activo

```bash
# Verificar que UFW bloquea acceso externo ANTES de exponer
sudo ufw status | grep -E "11434|18789"
# Debe mostrar "DENY" o no aparecer (solo Tailscale permitido)

# Configurar Ollama para aceptar conexiones Tailscale
echo 'export OLLAMA_HOST="0.0.0.0:11434"' >> ~/.zshrc
source ~/.zshrc

# Reiniciar Ollama
brew services restart ollama

# VERIFICAR: Solo debe ser accesible via Tailscale
curl -s http://127.0.0.1:11434/api/tags | head -1  # Debe funcionar
curl -s http://$(tailscale ip -4):11434/api/tags | head -1  # Debe funcionar via Tailscale
```

---

## Fase 3: MacBook Pro M1 Max (LLM Server)

### 3.1 LMStudio Link Setup

> ⚠️ **SEGURIDAD:** El bind `0.0.0.0` es SOLO para acceso via Tailscale.
> Asegúrate de que macOS Firewall bloquea conexiones directas desde internet.

```bash
# Instalar LMStudio si no existe
# https://lmstudio.ai/

# Configurar Link Server
# En LMStudio:
# 1. Ir a Local Server
# 2. Activar "Enable Local Server"
# 3. Puerto: 1234
# 4. Bind to: 0.0.0.0 (SOLO seguro con Tailscale + Firewall activo)

# Verificar que solo es accesible via Tailscale
# Desde el Mac Mini, probar:
curl -s http://$(tailscale ip -4):1234/v1/models  # Debe funcionar
```

### 3.2 Modelos Recomendados

```bash
# En LMStudio, descargar:
# - llama-3.1-70b-instruct.Q4_K_M.gguf (~40GB)
# - mixtral-8x7b-instruct.Q4_K_M.gguf (~24GB)
# - codestral-22b.Q4_K_M.gguf (~13GB)
# - qwen-2.5-72b-instruct.Q4_K_M.gguf (~42GB)
```

### 3.3 Script de Disponibilidad

```bash
cat > ~/openclaw-llm-server.sh << 'EOF'
#!/bin/bash
# Script para anunciar disponibilidad del LLM server

MACMINI_IP="100.x.x.x"  # IP Tailscale del Mac Mini

# Notificar al Mac Mini que estamos online
curl -X POST "http://${MACMINI_IP}:18789/api/cluster/announce" \
  -H "Content-Type: application/json" \
  -d '{
    "node": "macbook",
    "status": "online",
    "models": ["llama3.1:70b", "mixtral:8x7b", "codestral:22b"],
    "endpoint": "http://'$(tailscale ip -4)':1234"
  }' 2>/dev/null

echo "LLM Server announced at $(date)"
EOF

chmod +x ~/openclaw-llm-server.sh

# Añadir al login
echo "~/openclaw-llm-server.sh &" >> ~/.zshrc
```

### 3.4 Ollama como Backup

```bash
# Si no hay LMStudio, usar Ollama
brew install ollama

# Modelos grandes (cuantizados)
ollama pull llama3.1:70b-q4
ollama pull mixtral:8x7b-q4

# Configurar para acceso Tailscale
export OLLAMA_HOST="0.0.0.0:11434"
```

---

## Fase 4: VPS Hetzner (Gateway Público)

### 4.1 Configuración Nginx

```bash
cat > /etc/nginx/sites-available/openclaw-distributed << 'EOF'
upstream macmini_gateway {
    server 100.x.x.x:18789;  # IP Tailscale del Mac Mini
    keepalive 32;
}

upstream macmini_dashboard {
    server 100.x.x.x:18790;
}

server {
    listen 80;
    server_name tu-dominio.com;

    # Rate limiting
    limit_req zone=api burst=20 nodelay;

    # Health check local
    location /health {
        return 200 '{"status":"ok","node":"vps"}';
        add_header Content-Type application/json;
    }

    # API Gateway -> Mac Mini
    location /api {
        proxy_pass http://macmini_gateway/api;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 10s;
        proxy_read_timeout 60s;
    }

    # WebSocket -> Mac Mini
    location /ws {
        proxy_pass http://macmini_gateway/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 3600s;
    }

    # Mission Control -> Mac Mini
    location /dashboard {
        proxy_pass http://macmini_dashboard;
        proxy_http_version 1.1;
    }

    location / {
        proxy_pass http://macmini_gateway;
        proxy_http_version 1.1;
    }
}

limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
EOF

ln -sf /etc/nginx/sites-available/openclaw-distributed /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

### 4.2 Backup desde Mac Mini

En el Mac Mini, configurar backup remoto:

```bash
cat > $OPENCLAW_ROOT/scripts/backup-remote.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
VPS_IP="TU_VPS_IP"

# Backup local primero
/local/scripts/backup.sh

# Sync al VPS via rsync
rsync -avz --delete \
  -e "ssh -i ~/.ssh/id_rsa" \
  /Volumes/NVMe-4TB/openclaw/backups/ \
  openclaw@${VPS_IP}:/opt/openclaw/backups/macmini/

echo "Remote backup completed: $DATE"
EOF

chmod +x $OPENCLAW_ROOT/scripts/backup-remote.sh

# Cron diario a las 4am
(crontab -l 2>/dev/null; echo "0 4 * * * /Volumes/NVMe-4TB/openclaw/scripts/backup-remote.sh") | crontab -
```

---

## Fase 5: Sincronización de Memoria

### 5.1 Redis Replication

En Mac Mini (master):

```bash
# Configurar Redis como master
# /opt/homebrew/etc/redis.conf
replica-serve-stale-data yes
```

En VPS (replica - opcional):

```bash
# /etc/redis/redis.conf
replicaof 100.x.x.x 6379  # IP Tailscale del Mac Mini
```

### 5.2 Vector DB Sync

```bash
# Script de sync para conocimiento compartido
cat > $OPENCLAW_ROOT/scripts/sync-knowledge.sh << 'EOF'
#!/bin/bash
# Sincroniza la base de conocimiento con el VPS

rsync -avz --delete \
  -e "ssh -i ~/.ssh/id_rsa" \
  /Volumes/NVMe-4TB/openclaw/conocimiento/ \
  openclaw@${VPS_IP}:/opt/openclaw/conocimiento/

echo "Knowledge sync completed"
EOF

chmod +x $OPENCLAW_ROOT/scripts/sync-knowledge.sh
```

---

## Fase 6: Clientes Móviles

### 6.1 PWA para Dispositivos Móviles

```bash
# En Mission Control, añadir manifest.json
cat > $OPENCLAW_ROOT/mission-control/public/manifest.json << 'EOF'
{
  "name": "OPENCLAW Control",
  "short_name": "OPENCLAW",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#1a1a2e",
  "theme_color": "#4a9eff",
  "icons": [
    {
      "src": "/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    }
  ]
}
EOF
```

### 6.2 Acceso via Tailscale

En cada dispositivo móvil:
1. Instalar app Tailscale
2. Conectar a la red
3. Acceder a: `http://100.x.x.x:18790` (IP Tailscale del Mac Mini)

---

## Fase 7: Estrategia de LLMs Híbrida

### 7.1 Matriz de Decisión

| Tipo de Tarea | Modelo | Ubicación | Activación |
|---------------|--------|-----------|------------|
| Routing simple | llama3.2:3b | Mac Mini | Siempre |
| Código diario | qwen2.5:7b | Mac Mini | Siempre |
| Embeddings | nomic-embed | Mac Mini | Siempre |
| Código complejo | codestral:22b | MacBook | Bajo demanda |
| Razonamiento | llama3.1:70b | MacBook | Bajo demanda |
| Multi-tarea | mixtral:8x7b | MacBook | Bajo demanda |
| Fallback cloud | glm-5 | VPS/API | Si local no disponible |

### 7.2 Configuración de Fallback

```bash
cat > $OPENCLAW_ROOT/config/distributed/llm-routing.json << 'EOF'
{
  "tiers": [
    {
      "name": "tier-0-local-small",
      "provider": "ollama",
      "endpoint": "http://127.0.0.1:11434",
      "models": ["llama3.2:3b", "qwen2.5:7b"],
      "latency": "10-50ms",
      "cost": "free",
      "availability": "24/7"
    },
    {
      "name": "tier-1-local-large",
      "provider": "lmstudio",
      "endpoint": "http://100.x.x.x:1234",
      "models": ["llama3.1:70b", "mixtral:8x7b"],
      "latency": "100-500ms",
      "cost": "free",
      "availability": "on-demand"
    },
    {
      "name": "tier-2-cloud",
      "provider": "zai",
      "endpoint": "https://api.z.ai/v1",
      "models": ["glm-5", "glm-4.7"],
      "latency": "500-2000ms",
      "cost": "subscription",
      "availability": "24/7"
    },
    {
      "name": "tier-3-fallback",
      "provider": "minimax",
      "endpoint": "https://api.minimax.chat/v1",
      "models": ["abab6.5"],
      "latency": "1000-3000ms",
      "cost": "subscription",
      "availability": "24/7"
    }
  ],
  "routing_rules": {
    "simple_query": "tier-0",
    "code_generation": "tier-0",
    "complex_reasoning": "tier-1 || tier-2",
    "emergency": "tier-2 || tier-3"
  }
}
EOF
```

---

## Fase 8: Monitoreo Distribuido

### 8.1 Dashboard de Cluster

```bash
# Endpoint de estado en Mac Mini
cat > $OPENCLAW_ROOT/gateway/src/routes/cluster.js << 'EOF'
export default async function clusterRoutes(fastify) {
  fastify.get('/api/cluster/status', async () => {
    const nodes = await checkAllNodes();
    return {
      timestamp: Date.now(),
      nodes,
      summary: {
        total: nodes.length,
        online: nodes.filter(n => n.status === 'online').length,
        offline: nodes.filter(n => n.status === 'offline').length
      }
    };
  });
}

async function checkAllNodes() {
  const checks = await Promise.allSettled([
    checkNode('macmini', '127.0.0.1', 18789),
    checkNode('macbook', '100.x.x.x', 1234),
    checkNode('vps', '100.x.x.x', 80),
  ]);

  return checks.map((result, i) => ({
    name: ['macmini', 'macbook', 'vps'][i],
    status: result.status === 'fulfilled' && result.value ? 'online' : 'offline'
  }));
}

async function checkNode(name, ip, port) {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 2000);

    const response = await fetch(`http://${ip}:${port}/health`, {
      signal: controller.signal
    });

    clearTimeout(timeout);
    return response.ok;
  } catch {
    return false;
  }
}
EOF
```

---

## Resumen de Puertos y Accesos

| Puerto | Servicio | Mac Mini | MacBook | VPS | Acceso |
|--------|----------|----------|---------|-----|--------|
| 18789 | Gateway | ✓ | - | proxy | Tailscale + VPS |
| 18790 | Dashboard | ✓ | - | proxy | Tailscale + VPS |
| 11434 | Ollama | ✓ | ✓ | - | Tailscale |
| 1234 | LMStudio | - | ✓ | - | Tailscale |
| 6379 | Redis | ✓ | - | - | Localhost |
| 80/443 | HTTP/S | - | - | ✓ | Público |

---

## Checklist de Verificación Final

### Mac Mini (Core)
- [ ] **Tailscale IP**: `tailscale ip -4` → 100.x.x.x
- [ ] **Gateway**: `curl http://127.0.0.1:18789/health` → OK
- [ ] **Redis**: `redis-cli ping` → PONG
- [ ] **Ollama**: `ollama list` muestra modelos
- [ ] **Firewall**: Puertos 11434 y 18789 NO accesibles desde internet

### MacBook Pro (LLM Server)
- [ ] **Tailscale IP**: `tailscale ip -4` → 100.x.x.x diferente
- [ ] **LMStudio**: `curl http://127.0.0.1:1234/v1/models` → lista modelos
- [ ] **Ollama backup**: `ollama list` muestra modelos grandes
- [ ] **Firewall**: macOS Firewall activo

### VPS Hetzner (Gateway Público)
- [ ] **Nginx SSL**: `curl -I https://tu-dominio.com` → 200
- [ ] **Proxy funcionando**: Request a /health llega al Mac Mini
- [ ] **UFW activo**: Solo 22, 80, 443 expuestos

### Conectividad Tailscale
- [ ] **Mac Mini ↔ MacBook**: Ping exitoso
- [ ] **Mac Mini ↔ VPS**: Ping exitoso
- [ ] **MacBook → Mac Mini Gateway**: `curl http://100.x.x.x:18789/health`

### Dispositivos Móviles
- [ ] **Tailscale instalado**: App conectada
- [ ] **Acceso Gateway**: `curl http://100.x.x.x:18789/health` funciona
- [ ] **Dashboard**: Mission Control accesible en navegador

### Seguridad (CRÍTICO)
- [ ] **Gateway NO expuesto a internet** en Mac Mini
- [ ] **Ollama NO expuesto a internet** en ningún nodo
- [ ] **LMStudio NO expuesto a internet** en MacBook
- [ ] **Solo Tailscale puede acceder** a puertos 11434, 1234, 18789

### API Keys
- [ ] **Z.ai**: `$ZHIPUAI_API_KEY` configurado
- [ ] **Minimax** (opcional): `$MINIMAX_API_KEY` configurado
- [ ] **Telegram**: `$TELEGRAM_BOT_TOKEN` configurado

---

**Documento:** Ruta Sistema Distribuido
**Ubicación:** `docs/INSTALACION-PERSONAL/04-ruta-distribuida.md`
