# Ruta de Instalación: VPS Hetzner Standalone

**ID:** DOC-PER-INS-002
**Versión:** 1.0
**Fecha:** 2026-03-10
**Hardware:** VPS Hetzner 8 vCPU, 24GB RAM

---

## Resumen

Instalación de OPENCLAW-system en VPS Hetzner como servidor cloud standalone. Sin GPU local, usa APIs cloud para LLM y optimiza para 24/7 disponibilidad.

**Tiempo estimado:** 2-3 horas
**Dificultad:** Media-Alta (seguridad)

---

## Arquitectura Objetivo

```
VPS Hetzner (Cloud Standalone)
│
├── /opt/openclaw/                       ← Directorio principal
│   ├── gateway/                          ← WebSocket gateway
│   ├── orquestador/                      ← Tri-agente SIS
│   ├── catedraticos/                     ← 6 jefes
│   ├── memoria/                          ← Redis + Vector DB
│   ├── logs/                             ← Auditoría
│   ├── mission-control/                  ← Dashboard (opcional)
│   └── backups/                          ← Respaldos
│
├── /etc/nginx/                           ← Proxy inverso
│
└── PM2                                   ← Gestión procesos
```

---

## Fase 1: Preparación del VPS

### 1.1 Acceso Inicial

```bash
# Desde tu máquina local
ssh root@TU_IP_VPS

# Crear usuario no-root
adduser openclaw
usermod -aG sudo openclaw

# Copiar clave SSH
rsync --archive --chown=openclaw:openclaw ~/.ssh /home/openclaw/
```

### 1.2 Endurecimiento SSH

```bash
# Editar configuración SSH
sudo nano /etc/ssh/sshd_config

# Cambiar:
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes

# Reiniciar SSH
sudo systemctl reload sshd
```

### 1.3 Firewall UFW

```bash
# Configurar firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Activar
sudo ufw enable
```

### 1.4 Actualizar Sistema

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential curl wget git jq
```

---

## Fase 2: Dependencias

### 2.1 Node.js 22+

```bash
# Instalar Node.js via NodeSource
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# Verificar
node --version  # v22.x.x
npm --version
```

### 2.2 pnpm

```bash
npm install -g pnpm
pnpm --version
```

### 2.3 PM2

```bash
sudo npm install -g pm2
pm2 startup  # Configurar inicio automático
```

### 2.4 Redis

```bash
sudo apt install -y redis-server

# Configurar
sudo nano /etc/redis/redis.conf

# Cambiar:
bind 127.0.0.1
requirepass TU_PASSWORD_SEGURO
appendonly yes

# Reiniciar
sudo systemctl restart redis-server
sudo systemctl enable redis-server
```

### 2.5 Nginx

```bash
sudo apt install -y nginx
sudo systemctl enable nginx
```

---

## Fase 3: Estructura de Directorios

```bash
# Crear estructura
sudo mkdir -p /opt/openclaw/{gateway,orquestador,catedraticos,memoria,logs,mission-control,backups,scripts}

# Permisos
sudo chown -R openclaw:openclaw /opt/openclaw
chmod -R 755 /opt/openclaw

# Variables de entorno
echo 'export OPENCLAW_ROOT="/opt/openclaw"' >> ~/.bashrc
source ~/.bashrc
```

---

## Fase 4: Gateway WebSocket

### 4.1 Crear Proyecto

```bash
cd /opt/openclaw/gateway
pnpm init
pnpm add fastify @fastify/websocket @fastify/cors dotenv
mkdir -p src/{routes,middleware,utils}
```

### 4.2 Código Gateway

```bash
cat > /opt/openclaw/gateway/src/index.js << 'EOF'
import Fastify from 'fastify';
import websocket from '@fastify/websocket';
import cors from '@fastify/cors';
import dotenv from 'dotenv';

dotenv.config();

const fastify = Fastify({
  logger: {
    level: process.env.LOG_LEVEL || 'info',
    transport: {
      target: 'pino-pretty'
    }
  }
});

await fastify.register(websocket);
await fastify.register(cors, {
  origin: process.env.CORS_ORIGIN || '*'
});

// Health check
fastify.get('/health', async () => ({
  status: 'ok',
  timestamp: Date.now(),
  version: '1.0.0'
}));

// API Key middleware
fastify.addHook('onRequest', async (request, reply) => {
  if (request.url === '/health') return;

  const apiKey = request.headers['x-api-key'];
  if (!apiKey || apiKey !== process.env.API_KEY) {
    reply.code(401).send({ error: 'Unauthorized' });
  }
});

// WebSocket principal
fastify.register(async function (fastify) {
  fastify.get('/ws', { websocket: true }, (connection, req) => {
    connection.socket.on('message', async (message) => {
      try {
        const data = JSON.parse(message.toString());
        // Routing hacia orquestador
        const respuesta = await procesarSolicitud(data);
        connection.socket.send(JSON.stringify(respuesta));
      } catch (error) {
        connection.socket.send(JSON.stringify({ error: error.message }));
      }
    });
  });
});

// API REST
fastify.post('/api/solicitud', async (request, reply) => {
  const { mensaje, namespace } = request.body;
  return await procesarSolicitud({ mensaje, namespace });
});

const start = async () => {
  try {
    await fastify.listen({
      port: parseInt(process.env.PORT) || 18789,
      host: '127.0.0.1'
    });
    console.log('Gateway running on http://127.0.0.1:18789');
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();
EOF
```

### 4.3 Variables de Entorno

```bash
# Generar API key ANTES del heredoc (los heredocs con comillas no evalúan variables)
GATEWAY_API_KEY=$(openssl rand -hex 32)

cat > /opt/openclaw/gateway/.env << EOF
PORT=18789
API_KEY=${GATEWAY_API_KEY}
LOG_LEVEL=info
CORS_ORIGIN=*
EOF

# Guardar API key para referencia
echo "GATEWAY_API_KEY=${GATEWAY_API_KEY}" > /opt/openclaw/.api_keys
chmod 600 /opt/openclaw/.api_keys
```

---

## Fase 5: Orquestador (Sin Ollama)

En VPS sin GPU, usamos **APIs cloud** en lugar de Ollama.

### 5.1 Proveedor AI Configuración

```bash
cd /opt/openclaw/orquestador
pnpm init
pnpm add ai zod dotenv

mkdir -p src/{director,ejecutor,archivador,consenso,providers}
```

### 5.2 Provider Z.ai

```bash
cat > /opt/openclaw/orquestador/src/providers/zai.js << 'EOF'
// Provider para Z.ai API
import { createOpenAICompatible } from '@ai-sdk/openai-compatible';

const zai = createOpenAICompatible({
  name: 'zai',
  apiBase: process.env.ZAI_API_BASE || 'https://api.z.ai/v1',
  apiKey: process.env.ZAI_API_KEY,
});

export const models = {
  glm5: zai('glm-5'),
  glm47: zai('glm-4.7'),
  glm46: zai('glm-4.6'),
};

export default zai;
EOF
```

### 5.3 Provider Minimax

```bash
cat > /opt/openclaw/orquestador/src/providers/minimax.js << 'EOF'
// Provider para Minimax API
import { createOpenAICompatible } from '@ai-sdk/openai-compatible';

const minimax = createOpenAICompatible({
  name: 'minimax',
  apiBase: process.env.MINIMAX_API_BASE,
  apiKey: process.env.MINIMAX_API_KEY,
});

export const models = {
  abab6: minimax('abab6.5-chat'),
};

export default minimax;
EOF
```

### 5.4 Variables de Entorno

```bash
cat > /opt/openclaw/orquestador/.env << 'EOF'
# Z.ai (principal)
ZAI_API_KEY=tu_zai_api_key
ZAI_API_BASE=https://api.z.ai/v1

# Minimax (backup)
MINIMAX_API_KEY=tu_minimax_api_key
MINIMAX_API_BASE=https://api.minimax.chat/v1

# Mistral (opcional)
MISTRAL_API_KEY=tu_mistral_api_key

# Selección de modelo
DEFAULT_MODEL=glm-5
FALLBACK_MODEL=glm-4.7
EOF
```

### 5.5 Director con APIs Cloud

```bash
cat > /opt/openclaw/orquestador/src/director/index.js << 'EOF'
import { generateText } from 'ai';
import { models } from '../providers/zai.js';

export async function planificar(solicitud) {
  const prompt = `
Eres el Director del sistema OPENCLAW.
Analiza esta solicitud y determina:
1. Dominio (DES, INF, HOS, ACA, CRI, FIN, DEP, IDI, GEN)
2. Tareas necesarias
3. Recursos requeridos
4. Nivel de urgencia (1-5)

Solicitud: ${solicitud}

Responde SOLO en JSON válido:
{ "dominio": "XXX", "tareas": [], "recursos": [], "urgencia": N }
`;

  const { text } = await generateText({
    model: models.glm47,
    prompt,
  });

  try {
    return JSON.parse(text);
  } catch {
    return {
      dominio: 'GEN',
      tareas: [solicitud],
      recursos: [],
      urgencia: 3
    };
  }
}

export async function delegar(plan) {
  return {
    destino: `JEF-${plan.dominio}`,
    instrucciones: plan.tareas,
    recursos: plan.recursos,
    urgencia: plan.urgencia
  };
}
EOF
```

---

## Fase 6: Nginx Proxy

### 6.1 Configuración

```bash
sudo cat > /etc/nginx/sites-available/openclaw << 'EOF'
server {
    listen 80;
    server_name tu-dominio.com;  # O IP del VPS

    location /health {
        proxy_pass http://127.0.0.1:18789/health;
        proxy_http_version 1.1;
    }

    location /ws {
        proxy_pass http://127.0.0.1:18789/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /api {
        proxy_pass http://127.0.0.1:18789/api;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Rate limiting
    limit_req zone=api_limit burst=10 nodelay;
}

# Rate limiting zone
limit_req_zone $binary_remote_addr zone=api_limit=10m rate=10r/s;
EOF

sudo ln -sf /etc/nginx/sites-available/openclaw /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

### 6.2 HTTPS con Let's Encrypt

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d tu-dominio.com
```

---

## Fase 7: PM2 Configuración

### 7.1 ecosystem.config.js

```bash
cat > /opt/openclaw/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'gateway',
      cwd: '/opt/openclaw/gateway',
      script: 'pnpm',
      args: 'start',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 18789
      }
    },
    {
      name: 'orquestador',
      cwd: '/opt/openclaw/orquestador',
      script: 'pnpm',
      args: 'start',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G'
    }
  ]
};
EOF
```

### 7.2 Iniciar Servicios

```bash
cd /opt/openclaw
pm2 start ecosystem.config.js
pm2 save
```

---

## Fase 8: Monitoreo y Logs

### 8.1 Logs Estructurados

```bash
# Configurar rotación de logs
sudo cat > /etc/logrotate.d/openclaw << 'EOF'
/opt/openclaw/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 openclaw openclaw
}
EOF
```

### 8.2 Monitoreo Básico

```bash
# Script de health check
cat > /opt/openclaw/scripts/health-check.sh << 'EOF'
#!/bin/bash
LOG="/opt/openclaw/logs/health.log"

check_service() {
    if curl -s "http://127.0.0.1:$1/health" > /dev/null 2>&1; then
        echo "$(date) - $2: OK" >> $LOG
    else
        echo "$(date) - $2: FAIL" >> $LOG
        # Alerta o reinicio automático
        pm2 restart $3 2>/dev/null
    fi
}

check_service 18789 "Gateway" "gateway"
check_service 6379 "Redis" "" && redis-cli ping > /dev/null

pm2 list >> $LOG
EOF

chmod +x /opt/openclaw/scripts/health-check.sh

# Cron cada 5 minutos
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/openclaw/scripts/health-check.sh") | crontab -
```

---

## Fase 9: Backup Remoto

### 9.1 Script Backup

```bash
cat > /opt/openclaw/scripts/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/openclaw/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Redis
redis-cli -a $REDIS_PASSWORD BGSAVE
sleep 2
cp /var/lib/redis/dump.rdb "$BACKUP_DIR/redis_$DATE.rdb"

# Configuración
tar -czf "$BACKUP_DIR/config_$DATE.tar.gz" \
  --exclude='node_modules' \
  /opt/openclaw/*/package.json \
  /opt/openclaw/*/.env \
  /opt/openclaw/*/src

# Limpiar antiguos
find $BACKUP_DIR -type f -mtime +7 -delete

echo "Backup: $DATE"
EOF

chmod +x /opt/openclaw/scripts/backup.sh
```

---

## Resumen de Puertos

| Puerto | Servicio | Exposición |
|--------|----------|------------|
| 22 | SSH | Pública (UFW) |
| 80 | Nginx HTTP | Pública |
| 443 | Nginx HTTPS | Pública |
| 18789 | Gateway | Localhost (via Nginx) |
| 6379 | Redis | Localhost only |

---

## Checklist de Verificación Final

Antes de dar por completada la instalación, verifica:

### Servicios Core
- [ ] **Redis responde**: `redis-cli ping` → `PONG`
- [ ] **Gateway health**: `curl http://127.0.0.1:18789/health` → `{"status":"ok"}`
- [ ] **Director online**: `curl http://127.0.0.1:8081/health`
- [ ] **Ejecutor online**: `curl http://127.0.0.1:8082/health`
- [ ] **Archivador online**: `curl http://127.0.0.1:8083/health`

### LLM (APIs Cloud)
- [ ] **Z.ai configurado**: `echo $ZHIPUAI_API_KEY | head -c 10` muestra valor
- [ ] **API responde**: Test con curl a endpoint de Z.ai

### Nginx y SSL
- [ ] **Nginx config válida**: `sudo nginx -t` → `syntax is ok`
- [ ] **Certificado SSL**: `curl -I https://tu-dominio.com` → 200 OK
- [ ] **Redirección HTTP**: `curl -I http://tu-dominio.com` → 301 redirect

### Seguridad
- [ ] **UFW activo**: `sudo ufw status` → `Status: active`
- [ ] **Solo puertos necesarios**: 22, 80, 443 permitidos
- [ ] **Gateway NO expuesto**: Puerto 18789 NO en UFW allow
- [ ] **Redis NO expuesto**: Puerto 6379 NO accesible desde fuera

### PM2
- [ ] **Startup configurado**: `pm2 startup` ejecutado
- [ ] **Procesos guardados**: `pm2 save` ejecutado
- [ ] **Todos online**: `pm2 status` muestra todos como `online`

### Backup
- [ ] **Script existe**: `ls -la /opt/openclaw/scripts/backup.sh`
- [ ] **Cron configurado**: `crontab -l | grep backup`

---

**Documento:** Ruta VPS Hetzner Standalone
**Ubicación:** `docs/INSTALACION-PERSONAL/03-ruta-vps-hetzner.md`
