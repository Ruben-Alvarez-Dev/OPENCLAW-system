# Configuración Detallada

**ID:** DOC-IMP-CON-001
**Versión:** 1.1
**Fecha:** Marzo 2026
**Sistema:** OPENCLAW-system (OpenClaw)

---

## 1. Introducción

Este documento describe la configuración completa del OPENCLAW-system, incluyendo estructura de directorios, archivos de configuración, variables de entorno e integración con servicios externos.

---

## 2. Estructura de Directorios

### 2.1 Creación de Directorios

```bash
# Crear estructura de directorios
sudo mkdir -p /root/.openclaw/SIS_CORE/{config,data,logs,plugins,tmp}
sudo mkdir -p /root/.openclaw/SIS_CORE/data/{memoria,conocimiento}
sudo mkdir -p /root/.openclaw/SIS_CORE/config/agentes

# Establecer permisos
sudo chmod -R 750 /root/.openclaw
sudo chown -R $USER:$USER /root/.openclaw
```

### 2.2 Árbol de Directorios

```
/root/.openclaw/SIS_CORE/
├── config/
│   ├── default.json          # Configuración base
│   ├── production.json       # Overrides para producción
│   ├── providers.json        # Configuración de proveedores IA
│   ├── channels.json         # Configuración de canales
│   └── agentes/
│       ├── director.json
│       ├── ejecutor.json
│       └── archivador.json
├── data/
│   ├── memory/
│   └── knowledge/
├── logs/
├── plugins/
└── tmp/
```

---

## 3. Configuración de PM2 (ecosystem.config.js)

```javascript
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
      env: { NODE_ENV: 'production', LOG_LEVEL: 'info' },
      error_file: '/root/.openclaw/SIS_CORE/logs/gateway-error.log',
      out_file: '/root/.openclaw/SIS_CORE/logs/gateway-out.log',
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
      env: { NODE_ENV: 'production', LOG_LEVEL: 'info' },
      error_file: '/root/.openclaw/SIS_CORE/logs/director-error.log',
      out_file: '/root/.openclaw/SIS_CORE/logs/director-out.log',
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
      env: { NODE_ENV: 'production', LOG_LEVEL: 'info' },
      error_file: '/root/.openclaw/SIS_CORE/logs/ejecutor-error.log',
      out_file: '/root/.openclaw/SIS_CORE/logs/ejecutor-out.log',
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
      env: { NODE_ENV: 'production', LOG_LEVEL: 'info' },
      error_file: '/root/.openclaw/SIS_CORE/logs/archivist-error.log',
      out_file: '/root/.openclaw/SIS_CORE/logs/archivist-out.log',
      time: true
    }
  ]
};
```

### Opciones de Restart

```javascript
restart_delay: 4000,
exp_backoff_restart_delay: 100,
max_restarts: 10,
restart_window: 60000,
kill_timeout: 5000,
wait_ready: true,
listen_timeout: 10000
```

---

## 4. Configuración del Gateway

### gateway.json

```json
{
  "gateway": {
    "host": "127.0.0.1",
    "port": 18789,
    "protocol": "ws",
    "maxConnections": 100,
    "connectionTimeout": 30000,
    "pingInterval": 25000,
    "pongTimeout": 10000
  },
  "router": {
    "defaultGear": "director",
    "routingStrategy": "round-robin",
    "healthCheckInterval": 15000
  },
  "security": {
    "tokenEncryption": true,
    "rateLimit": { "enabled": true, "windowMs": 60000, "maxRequests": 100 }
  }
}
```

### Verificación

```bash
netstat -tlnp | grep 18789
curl -v http://127.0.0.1:18789/health
```

---

## 5. Configuración de Engranajes

### Director (gears/director.json)

```json
{
  "gear": { "name": "director", "type": "coordinator", "gatewayUrl": "ws://127.0.0.1:18789" },
  "capabilities": ["routing", "coordination", "load-balancing"],
  "routes": { "telegram": "ejecutor", "cli": "ejecutor", "internal": "archivador" },
  "healthCheck": { "interval": 30000, "timeout": 5000 },
  "logging": { "level": "info", "format": "json" }
}
```

### Ejecutor (gears/ejecutor.json)

```json
{
  "gear": { "name": "ejecutor", "type": "processor", "gatewayUrl": "ws://127.0.0.1:18789" },
  "processing": { "maxConcurrent": 10, "timeout": 60000, "retryAttempts": 3 },
  "model": { "primary": "zai/glm-4.5-air", "fallback": ["openai/gpt-4o-mini", "anthropic/claude-3-5-sonnet"] },
  "memory": { "enabled": true, "ttl": 3600, "maxSize": "100MB" },
  "logging": { "level": "info", "format": "json" }
}
```

### Archivador (gears/archivador.json)

```json
{
  "gear": { "name": "archivador", "type": "storage", "gatewayUrl": "ws://127.0.0.1:18789" },
  "storage": {
    "type": "sqlite",
    "path": "/root/.openclaw/SIS_CORE/data/memory/conversations.db",
    "pragmas": { "journal_mode": "WAL", "synchronous": "NORMAL" }
  },
  "vectorStore": { "enabled": true, "path": "/root/.openclaw/SIS_CORE/data/knowledge/embeddings.db", "dimensions": 1536 },
  "retention": { "conversations": 2592000, "context": 604800 },
  "logging": { "level": "info", "format": "json" }
}
```

---

## 6. Configuración de Proveedores de IA

### providers.json

```json
{
  "providers": {
    "zai": {
      "name": "zhipuai",
      "baseUrl": "https://open.bigmodel.cn/api/paas/v4",
      "models": {
        "glm-4.5-air": { "enabled": true, "contextWindow": 128000, "maxOutput": 4096, "temperature": 0.7 },
        "glm-4-flash": { "enabled": true, "contextWindow": 128000, "maxOutput": 4096, "temperature": 0.5 }
      },
      "rateLimit": { "requestsPerMinute": 60, "tokensPerMinute": 100000 },
      "timeout": 30000
    },
    "openai": {
      "name": "openai",
      "baseUrl": "https://api.openai.com/v1",
      "models": {
        "gpt-4o": { "enabled": true, "contextWindow": 128000, "maxOutput": 4096 },
        "gpt-4o-mini": { "enabled": true, "contextWindow": 128000, "maxOutput": 4096 }
      },
      "rateLimit": { "requestsPerMinute": 500 },
      "timeout": 30000
    },
    "anthropic": {
      "name": "anthropic",
      "baseUrl": "https://api.anthropic.com/v1",
      "models": { "claude-3-5-sonnet": { "enabled": true, "contextWindow": 200000, "maxOutput": 8192 } },
      "rateLimit": { "requestsPerMinute": 100 },
      "timeout": 60000
    }
  },
  "fallback": { "strategy": "sequential", "order": ["zai", "openai", "anthropic"], "maxAttempts": 3 }
}
```

### Variables de Entorno (.env)

```bash
# /root/.openclaw/SIS_CORE/config/.env
NODE_ENV=production
ZHIPUAI_API_KEY=tu_api_key_de_zhipuai
OPENAI_API_KEY=sk-tu_api_key_de_openai
ANTHROPIC_API_KEY=sk-ant-tu_api_key_de_anthropic
OPENCLAW_ENCRYPTION_KEY=clave_de_32_caracteres_para_encriptacion
TELEGRAM_BOT_TOKEN=tu_token_de_bot_telegram
GATEWAY_URL=ws://127.0.0.1:18789
LOG_LEVEL=info
LOG_FORMAT=json
```

---

## 7. Configuración de Canales (channels.json)

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "type": "bot",
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "polling": { "enabled": true, "interval": 1000, "timeout": 30 },
      "rateLimit": { "messagesPerSecond": 30, "messagesPerMinute": 500 },
      "features": { "parseMode": "Markdown", "disableWebPagePreview": false },
      "commands": [
        { "command": "start", "description": "Iniciar conversacion" },
        { "command": "reset", "description": "Reiniciar contexto" },
        { "command": "help", "description": "Mostrar ayuda" }
      ]
    },
    "cli": { "enabled": true, "type": "local", "prompt": "cko> " },
    "gateway": { "enabled": true, "type": "websocket", "url": "ws://127.0.0.1:18789" }
  }
}
```

### Obtener Token Telegram

```bash
# 1. Buscar @BotFather en Telegram
# 2. Enviar /newbot y seguir instrucciones
# 3. Guardar el token proporcionado

# Verificar token
curl "https://api.telegram.org/bot<TU_TOKEN>/getMe"
```

---

## 8. Configuración de Seguridad (security.json)

```json
{
  "security": {
    "tokenEncryption": { "enabled": true, "algorithm": "aes-256-gcm", "keyLength": 32 },
    "dataEncryption": { "enabled": true, "algorithm": "aes-256-cbc" },
    "secrets": { "storage": "env", "rotationDays": 90 }
  },
  "rateLimit": {
    "enabled": true,
    "global": { "windowMs": 60000, "maxRequests": 1000 },
    "perUser": { "windowMs": 60000, "maxRequests": 30 },
    "perChannel": { "telegram": { "windowMs": 1000, "maxRequests": 30 } }
  }
}
```

---

## 9. Configuración de Logs (logging.json)

```json
{
  "logging": {
    "level": "info",
    "format": "json",
    "outputs": ["console", "file"],
    "file": {
      "path": "/root/.openclaw/SIS_CORE/logs",
      "maxSize": "50M",
      "maxFiles": 10,
      "compress": true
    },
    "rotation": { "enabled": true, "interval": "daily" }
  }
}
```

### Niveles de Log

| Nivel | Uso |
|-------|-----|
| error | Errores críticos que requieren atención |
| warn | Advertencias no críticas |
| info | Información general de operación |
| debug | Información detallada para debugging |

---

## 10. Checklist de Configuración

- [ ] Estructura de directorios creada
- [ ] ecosystem.config.js configurado
- [ ] Gateway configurado en puerto 18789
- [ ] Engranajes (Director, Ejecutor, Archivador) configurados
- [ ] Proveedores de IA con API keys válidas
- [ ] Canal Telegram configurado con token
- [ ] Seguridad y encriptación habilitadas
- [ ] Logs configurados con rotación
- [ ] Variables de entorno en archivo .env
- [ ] Permisos de archivos correctos (750)

---

## 11. Próximos Pasos

Continuar con:
- [03-despliegue.md](./03-despliegue.md) - Despliegue en Producción
- [04-monitoreo.md](./04-monitoreo.md) - Monitoreo y Logs

---

| Fecha | Versión | Cambio |
|-------|---------|--------|
| 2026-03-09 | 1.0 | Documento inicial |

*Documento generado para OPENCLAW-system v1.0*
