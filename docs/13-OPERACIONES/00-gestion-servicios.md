# Gestión de Servicios PM2

**ID:** DOC-OPE-GES-001
**Versión:** 1.1
**Última actualización:** 2026-03-10
**Sistema:** OPENCLAW-system (OpenClaw)

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [Comandos Básicos de PM2](#comandos-básicos-de-pm2)
3. [Gestión del Sistema](#gestión-del-sistema)
4. [Configuración de PM2](#configuración-de-pm2)
5. [Clustering y Modo Fork](#clustering-y-modo-fork)
6. [Variables de Entorno](#variables-de-entorno)
7. [Gestión de Logs](#gestión-de-logs)
8. [Integración con Systemd/Launchd](#integración-con-systemdlaunchd)
9. [Referencias Cruzadas](#referencias-cruzadas)

---

## Introducción

PM2 (Process Manager 2) es el gestor de procesos utilizado para administrar los tres agentes del OPENCLAW-system: **Director**, **Ejecutor** y **Archivador**. Su elección se debe a su capacidad de mantener procesos Node.js en ejecución continua, reinicio automático ante fallos, y gestión centralizada de logs.

### Arquitectura de Procesos

```
┌─────────────────────────────────────────────────────────────┐
│                     PM2 Process Manager                     │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Director   │  │   Ejecutor   │  │  Archivador  │      │
│  │   :3000      │  │   :3001      │  │   :3002      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                 │                 │               │
│         └────────────────┴─────────────────┘               │
│                    Redis (Bus de mensajes)                  │
└─────────────────────────────────────────────────────────────┘
```

### Responsabilidades por Agente

| Agente | Puerto | Modo | Responsabilidad Principal |
|-----------|--------|------|---------------------------|
| Director | 3000 | Fork | Coordinación, routing, orquestación |
| Ejecutor | 3001 | Cluster | Procesamiento de tareas, IA, RAG |
| Archivador | 3002 | Fork | Persistencia, Vault, búsquedas |

---

## Comandos Básicos de PM2

### Iniciar Procesos

```bash
# Iniciar un proceso simple
pm2 start app.js

# Iniciar con nombre personalizado
pm2 start director.js --name "sis-director"

# Iniciar con configuración ecosystem
pm2 start ecosystem.config.js

# Iniciar solo un servicio específico
pm2 start ecosystem.config.js --only director

# Iniciar en modo producción
pm2 start ecosystem.config.js --env production
```

### Detener Procesos

```bash
pm2 stop director          # Detener proceso específico
pm2 stop all              # Detener todos
pm2 stop sis-ejecutor       # Detener pero mantener en memoria
```

### Reiniciar Procesos

```bash
pm2 restart director              # Reinicio completo
pm2 restart all                  # Reiniciar todos
pm2 gracefulReload director       # Reinicio graceful
pm2 restart director --update-env # Con actualización de variables
```

### Eliminar Procesos

```bash
pm2 delete director              # Eliminar de la lista
pm2 delete all                  # Eliminar todos
pm2 delete director && pm2 flush # Eliminar y limpiar logs
```

### Monitoreo

```bash
pm2 list                  # Lista de procesos
pm2 monit                 # Monitor interactivo
pm2 logs                  # Logs en tiempo real
pm2 logs manager --lines 100  # Logs específicos
pm2 show manager          # Información detallada
pm2 describe manager      # Métricas en JSON
```

### Persistencia

```bash
pm2 save          # Guardar lista de procesos
pm2 resurrect     # Restaurar procesos guardados
pm2 save --force  # Forzar guardado
```

---

## Gestión del Sistema

### Orden de Inicio de Componentes

El orden de inicio es crítico debido a las dependencias entre servicios:

```bash
#!/bin/bash
# sis-start.sh - Inicio ordenado del sistema

set -e
echo "🚀 Iniciando OPENCLAW-system..."

# 1. Verificar Redis
echo "📡 Verificando Redis..."
redis-cli ping || {
    echo "❌ Redis no disponible. Iniciando..."
    redis-server --daemonize yes
    sleep 2
}

# 2. Iniciar Director
echo "🔧 Iniciando Director..."
pm2 start ecosystem.config.js --only director
sleep 3

until curl -s http://localhost:3000/health > /dev/null; do
    echo "⏳ Esperando a Director..."
    sleep 1
done
echo "✅ Director listo"

# 3. Iniciar Ejecutor
echo "⚙️ Iniciando Ejecutor..."
pm2 start ecosystem.config.js --only ejecutor
sleep 3

until curl -s http://localhost:3001/health > /dev/null; do
    sleep 1
done
echo "✅ Ejecutor listo"

# 4. Iniciar Archivador
echo "📚 Iniciando Archivador..."
pm2 start ecosystem.config.js --only archivador
sleep 3

until curl -s http://localhost:3002/health > /dev/null; do
    sleep 1
done
echo "✅ Archivador listo"

echo "🎉 OPENCLAW-system completamente operativo"
pm2 list
```

### Orden de Detención

```bash
#!/bin/bash
# sis-stop.sh - Detención ordenada del sistema

echo "🛑 Deteniendo OPENCLAW-system..."

# Orden inverso al inicio
echo "📚 Deteniendo Archivador..."
pm2 stop archivador
sleep 2

echo "⚙️ Deteniendo Ejecutor..."
pm2 stop ejecutor
sleep 2

echo "🔧 Deteniendo Director..."
pm2 stop director

echo "✅ OPENCLAW-system detenido correctamente"
pm2 list
```

### Reinicio Individual de Engranajes

```bash
#!/bin/bash
# sis-restart-gear.sh - Reinicio individual con validación

GEAR=$1

if [ -z "$GEAR" ]; then
    echo "Uso: $0 <director|ejecutor|archivador>"
    exit 1
fi

case $GEAR in
    director)   PORT=3000 ;;
    ejecutor)    PORT=3001 ;;
    archivador) PORT=3002 ;;
    *)
        echo "Engranaje no válido: $GEAR"
        exit 1
        ;;
esac

echo "🔄 Reiniciando $GEAR..."
pm2 gracefulReload $GEAR
sleep 5

if curl -sf http://localhost:$PORT/health > /dev/null; then
    echo "✅ $GEAR reiniciado correctamente"
else
    echo "❌ Error: $GEAR no responde"
    exit 1
fi
```

### Actualización en Caliente (Zero-Downtime)

```bash
#!/bin/bash
# sis-deploy.sh - Despliegue sin downtime

echo "📦 Actualizando OPENCLAW-system..."

git pull origin main
npm ci --production

for GEAR in director ejecutor archivador; do
    echo "🔄 Actualizando $GEAR..."
    pm2 reload $GEAR --update-env
    sleep 5
    echo "✅ $GEAR actualizado"
done

pm2 save
echo "🎉 Despliegue completado sin downtime"
pm2 list
```

---

## Configuración de PM2

### Archivo ecosystem.config.js

```javascript
// ecosystem.config.js - Configuración PM2 para OPENCLAW-system

module.exports = {
  apps: [
    {
      name: 'director',
      script: './src/gears/director/index.js',
      instances: 1,
      exec_mode: 'fork',

      env_production: {
        NODE_ENV: 'production',
        PORT: 3000,
        LOG_LEVEL: 'info',
        REDIS_URL: 'redis://localhost:6379',
        GEAR_NAME: 'director'
      },

      env_development: {
        NODE_ENV: 'development',
        PORT: 3000,
        LOG_LEVEL: 'debug',
        REDIS_URL: 'redis://localhost:6379',
        GEAR_NAME: 'director'
      },

      max_memory_restart: '500M',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      error_file: './logs/director-error.log',
      out_file: './logs/director-out.log',
      merge_logs: true,

      exp_backoff_restart_delay: 100,
      max_restarts: 10,
      restart_delay: 1000,
      autorestart: true,
      watch: false,

      kill_timeout: 5000,
      wait_ready: true,
      listen_timeout: 3000
    },

    {
      name: 'ejecutor',
      script: './src/gears/ejecutor/index.js',
      instances: 4,
      exec_mode: 'cluster',

      env_production: {
        NODE_ENV: 'production',
        PORT: 3001,
        LOG_LEVEL: 'info',
        REDIS_URL: 'redis://localhost:6379',
        GEAR_NAME: 'ejecutor',
        MAX_CONCURRENT_TASKS: 5
      },

      env_development: {
        NODE_ENV: 'development',
        PORT: 3001,
        LOG_LEVEL: 'debug',
        REDIS_URL: 'redis://localhost:6379',
        GEAR_NAME: 'ejecutor',
        MAX_CONCURRENT_TASKS: 2
      },

      max_memory_restart: '1G',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      error_file: './logs/ejecutor-error.log',
      out_file: './logs/ejecutor-out.log',
      merge_logs: true,

      cron_restart: '0 3 * * *'  # Reinicio diario a las 3am
    },

    {
      name: 'archivador',
      script: './src/gears/archivador/index.js',
      instances: 1,
      exec_mode: 'fork',

      env_production: {
        NODE_ENV: 'production',
        PORT: 3002,
        LOG_LEVEL: 'info',
        REDIS_URL: 'redis://localhost:6379',
        GEAR_NAME: 'archivador',
        VAULT_PATH: './vault'
      },

      env_development: {
        NODE_ENV: 'development',
        PORT: 3002,
        LOG_LEVEL: 'debug',
        REDIS_URL: 'redis://localhost:6379',
        GEAR_NAME: 'archivador',
        VAULT_PATH: './vault-dev'
      },

      max_memory_restart: '800M',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      error_file: './logs/archivador-error.log',
      out_file: './logs/archivador-out.log',
      merge_logs: true,

      max_restarts: 5,
      restart_delay: 5000
    }
  ],

  deploy: {
    production: {
      user: 'openclaw',
      host: ['openclaw-system.example.com'],
      ref: 'origin/main',
      repo: 'git@github.com:openclaw/openclaw-system.git',
      path: '/opt/openclaw-system',
      'post-deploy': 'npm ci && pm2 reload ecosystem.config.js --env production'
    }
  }
};
```

---

## Clustering y Modo Fork

### Diferencias entre Modos

| Característica | Fork Mode | Cluster Mode |
|----------------|-----------|--------------|
| Instancias | 1 proceso | Múltiples procesos |
| CPUs utilizados | 1 | Todos los disponibles |
| Memoria compartida | No | No |
| Comunicación | IPC | IPC via Master |
| Caso de uso | Estado local | Stateless, HTTP |
| Socket/WebSocket | Compatible | Requiere Redis Adapter |

### Configuracion de Cluster para Ejecutor

El Ejecutor usa modo cluster por su naturaleza stateless:

```javascript
{
  name: 'ejecutor',
  script: './src/gears/ejecutor/index.js',
  instances: 4,  // o 'max' para usar todos los CPUs
  exec_mode: 'cluster'
}
```

### WebSocket con Cluster

Para WebSocket en cluster, usar Redis Adapter:

```javascript
// src/gears/ejecutor/websocket.js
const { Server } = require('socket.io');
const { createAdapter } = require('@socket.io/redis-adapter');
const Redis = require('ioredis');

const io = new Server(httpServer, {
  cors: { origin: '*' }
});

const pubClient = new Redis(process.env.REDIS_URL);
const subClient = pubClient.duplicate();

io.adapter(createAdapter(pubClient, subClient));
```

---

## Variables de Entorno

### Estructura de Variables

```bash
# .env.production
NODE_ENV=production
REDIS_URL=redis://localhost:6379

# APIs de IA
OPENAI_API_KEY=sk-xxx
ANTHROPIC_API_KEY=sk-ant-xxx
GOOGLE_AI_KEY=xxx

# Configuración del cluster
CLUSTER_NAME=openclaw-production
LOG_LEVEL=info

# Archivist
VAULT_PATH=/opt/openclaw-system/vault
BACKUP_PATH=/opt/openclaw-system/backups

# Seguridad
JWT_SECRET=xxx
ENCRYPTION_KEY=xxx
```

### Carga de Variables por Servicio

```bash
pm2 start ecosystem.config.js --env production
pm2 restart all --update-env
pm2 start manager.js --env production -- --custom-flag
```

### Validación de Variables

```javascript
// src/config/env.js
const requiredEnvVars = [
  'NODE_ENV',
  'REDIS_URL',
  'PORT',
  'GEAR_NAME'
];

function validateEnv() {
  const missing = requiredEnvVars.filter(v => !process.env[v]);
  if (missing.length > 0) {
    throw new Error(`Variables faltantes: ${missing.join(', ')}`);
  }
}

module.exports = { validateEnv };
```

---

## Gestión de Logs

### Configuración de Logs en PM2

```javascript
{
  log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
  error_file: './logs/director-error.log',
  out_file: './logs/director-out.log',
  merge_logs: true
}
```

### Comandos de Logs

```bash
pm2 logs                    # Ver logs en tiempo real
pm2 logs director           # Logs de un servicio
pm2 logs director --lines 200  # Últimas N líneas
pm2 flush                   # Limpiar logs
pm2 reloadLogs              # Rotación manual
```

### Rotación con pm2-logrotate

```bash
pm2 install pm2-logrotate

pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 30
pm2 set pm2-logrotate:compress true
pm2 set pm2-logrotate:dateFormat YYYY-MM-DD_HH-mm-ss
```

---

## Integración con Systemd/Launchd

### Linux (Systemd)

```bash
# Generar servicio systemd
pm2 startup systemd

# Output ejemplo:
# sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u openclaw --hp /home/openclaw

pm2 save

# El servicio se crea en:
# /etc/systemd/system/pm2-openclaw.service
```

### macOS (Launchd)

```bash
# Generar plist
pm2 startup launchd

# Comando sugerido:
# sudo env PATH=$PATH:/usr/local/bin pm2 startup launchd -u ruben --hp /Users/ruben

pm2 save

# El plist se crea en:
# ~/Library/LaunchAgents/pm2.ruben.plist
```

### Verificar Startup

```bash
pm2 startup      # Verificar configuración
pm2 list         # Estado actual
pm2 save --force # Forzar guardado
```

---

## Referencias Cruzadas

- **[01-logs-auditoria.md](./01-logs-auditoria.md)** - Sistema detallado de logs y auditoría
- **[02-backups.md](./02-backups.md)** - Estrategia de backups para PM2 y configuraciones
- **[03-optimizacion.md](./03-optimizacion.md)** - Optimización de rendimiento de procesos
- **[../01-SISTEMA/00-arquitectura-maestra.md](../01-SISTEMA/00-arquitectura-maestra.md)** - Arquitectura general del OPENCLAW-system
- **[../12-IMPLEMENTACION/03-despliegue.md](../12-IMPLEMENTACION/03-despliegue.md)** - Despliegue en producción

---

> **Documentación relacionada:** Ver [documentación oficial de PM2](https://pm2.keymetrics.io/docs/usage/quick-start/) para referencia completa de comandos.
