# Logs y Auditoría

**ID:** DOC-OPE-LOG-001
**Versión:** 1.0
**Última actualización:** 2026-03-09
**Cluster:** OPENCLAW-system OpenClaw

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [Sistema de Logs del OPENCLAW-system](#sistema-de-logs-del-openclaw-system)
3. [Formato de Logs](#formato-de-logs)
4. [Niveles de Severidad](#niveles-de-severidad)
5. [Rotación de Logs](#rotación-de-logs)
6. [Sistema de Auditoría](#sistema-de-auditoría)
7. [Herramientas de Análisis](#herramientas-de-análisis)
8. [Alertas basadas en Logs](#alertas-basadas-en-logs)
9. [Exportación para Cumplimiento](#exportación-para-cumplimiento)
10. [Referencias Cruzadas](#referencias-cruzadas)

---

## Introducción

El sistema de logs y auditoría del OPENCLAW-system proporciona trazabilidad completa de todas las operaciones, facilitando la depuración, el monitoreo de seguridad y el cumplimiento normativo. Todos los logs siguen un formato JSON estructurado para facilitar su análisis automatizado.

### Arquitectura de Logging

```
┌─────────────────────────────────────────────────────────────┐
│                    Sistema de Logs                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Director   │  │  Ejecutor   │  │ Archivador  │        │
│  │   Logger    │  │   Logger    │  │   Logger    │        │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │
│         └────────────────┴────────────────┘                │
│                          │                                  │
│                   ┌──────▼──────┐                          │
│                   │   Winston   │                          │
│                   │   (Core)    │                          │
│                   └──────┬──────┘                          │
│         ┌────────────────┼────────────────┐                │
│         ▼                ▼                ▼                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Console   │  │    Files    │  │    Redis    │        │
│  │  (Dev/Debug)│  │ (Persistent)│  │   (Buffer)  │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

---

## Sistema de Logs del OPENCLAW-system

### Fuentes de Logs

| Fuente | Ubicación | Contenido |
|--------|-----------|-----------|
| PM2 | `~/.pm2/logs/` | Output de procesos, errores de sistema |
| Director | `./logs/director-*.log` | Coordinación, routing, decisiones |
| Ejecutor | `./logs/ejecutor-*.log` | Procesamiento, IA, RAG |
| Archivador | `./logs/archivador-*.log` | Persistencia, Vault, búsquedas |
| Gateway | `./logs/gateway-*.log` | HTTP requests, WebSocket |
| R-P-V | `./logs/rpv-*.log` | Comunicación Reasoning-Planning-Verification |

### Configuración de Winston Logger

```javascript
// src/config/logger.js
const winston = require('winston');
const { format, transports } = winston;
const { combine, timestamp, json, errors, printf } = format;

const customFormat = combine(
  errors({ stack: true }),
  timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
  json(),
  printf(({ level, message, timestamp, gear, ...metadata }) => {
    return JSON.stringify({
      timestamp,
      level,
      gear: gear || process.env.GEAR_NAME,
      message,
      ...metadata
    });
  })
);

const createLogger = (gearName) => {
  return winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: customFormat,
    defaultMeta: { gear: gearName },
    transports: [
      new transports.Console({
        format: combine(format.colorize(), format.simple()),
        silent: process.env.NODE_ENV === 'production'
      }),
      
      new transports.File({
        filename: `./logs/${gearName}-error.log`,
        level: 'error',
        maxsize: 10485760, // 10MB
        maxFiles: 5
      }),
      
      new transports.File({
        filename: `./logs/${gearName}-combined.log`,
        maxsize: 52428800, // 50MB
        maxFiles: 10
      })
    ]
  });
};

module.exports = { createLogger };
```

### Logs por Engranaje

```javascript
// src/gears/director/index.js
const { createLogger } = require('../../config/logger');
const logger = createLogger('director');

logger.info('Director iniciado', {
  port: process.env.PORT,
  version: '1.0.0'
});

logger.debug('Routing request', {
  requestId: 'req-123',
  target: 'ejecutor',
  action: 'process-query'
});

logger.error('Error en coordinación', {
  error: err.message,
  stack: err.stack,
  requestId: 'req-123'
});
```

---

## Formato de Logs

### Estructura JSON Estandarizada

```json
{
  "timestamp": "2026-03-09T14:30:00.123Z",
  "level": "info",
  "gear": "ejecutor",
  "message": "Query procesada exitosamente",
  "requestId": "req-a1b2c3d4",
  "userId": "user-123",
  "duration": 1234,
  "metadata": {
    "model": "gpt-4o",
    "tokens": 256,
    "action": "rag-query"
  }
}
```

### Campos Obligatorios

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `timestamp` | ISO 8601 | Fecha y hora UTC |
| `level` | string | Nivel de severidad |
| `gear` | string | Engranaje origen (director/ejecutor/archivador) |
| `message` | string | Mensaje descriptivo |
| `requestId` | string | ID único de petición (trazabilidad) |

### Campos Opcionales

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `userId` | string | ID de usuario (si aplica) |
| `duration` | number | Tiempo en ms |
| `error` | object | Detalles del error |
| `metadata` | object | Información adicional contextual |

---

## Niveles de Severidad

### Definición de Niveles

```javascript
const LOG_LEVELS = {
  error: 0,   // Errores críticos que impiden operación
  warn: 1,    // Advertencias, posible problema
  info: 2,    // Información general de operación
  http: 3,    // Logs de peticiones HTTP
  debug: 4,   // Información detallada de depuración
  trace: 5    // Traza detallada de ejecución
};
```

### Uso por Nivel

```javascript
// ERROR: Fallo crítico
logger.error('Fallo al conectar con Redis', {
  error: err.message,
  host: process.env.REDIS_URL
});

// WARN: Advertencia
logger.warn('Memoria alta detectada', {
  usage: '85%',
  threshold: '80%'
});

// INFO: Información operativa
logger.info('Ejecutor procesando tarea', {
  taskId: 'task-123',
  queue: 'pending'
});

// DEBUG: Depuración
logger.debug('Estado interno', {
  queueSize: 5,
  activeConnections: 3
});

// TRACE: Traza detallada
logger.trace('Entrada a función', {
  function: 'processRAG',
  args: { query: 'test' }
});
```

### Configuración por Entorno

| Entorno | Nivel por Defecto |
|---------|-------------------|
| development | debug |
| staging | info |
| production | warn |

---

## Rotación de Logs

### Configuración con pm2-logrotate

```bash
# Instalar módulo
pm2 install pm2-logrotate

# Configuración
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 30
pm2 set pm2-logrotate:compress true
pm2 set pm2-logrotate:dateFormat YYYY-MM-DD_HH-mm-ss
pm2 set pm2-logrotate:rotateModule true
pm2 set pm2-logrotate:workerInterval 30
pm2 set pm2-logrotate:rotateInterval '0 0 * * *'
```

### Rotación Manual con logrotate (Linux)

```bash
# /etc/logrotate.d/openclaw-system

/opt/openclaw-system/logs/*.log {
    daily
    rotate 90
    compress
    delaycompress
    missingok
    notifempty
    create 0640 openclaw openclaw
    sharedscripts
    postrotate
        pm2 reloadLogs
    endscript
}
```

### Script de Archivado

```bash
#!/bin/bash
# scripts/archive-logs.sh

LOG_DIR="./logs"
ARCHIVE_DIR="./logs/archive"
RETENTION_DAYS=90

mkdir -p "$ARCHIVE_DIR"

# Comprimir logs con más de 7 días
find "$LOG_DIR" -name "*.log" -mtime +7 -exec gzip {} \;

# Mover a archivo
find "$LOG_DIR" -name "*.log.gz" -exec mv {} "$ARCHIVE_DIR/" \;

# Eliminar logs antiguos
find "$ARCHIVE_DIR" -name "*.log.gz" -mtime +$RETENTION_DAYS -delete

echo "Logs archivados correctamente"
```

---

## Sistema de Auditoría

### Eventos de Auditoría

```javascript
// src/utils/audit.js
const { createLogger } = require('../config/logger');
const auditLogger = createLogger('audit');

const AuditEvents = {
  // Autenticación
  LOGIN_SUCCESS: 'AUTH_LOGIN_SUCCESS',
  LOGIN_FAILED: 'AUTH_LOGIN_FAILED',
  LOGOUT: 'AUTH_LOGOUT',
  
  // Operaciones
  QUERY_EXECUTED: 'OP_QUERY_EXECUTED',
  DECISION_MADE: 'OP_DECISION_MADE',
  VAULT_WRITE: 'OP_VAULT_WRITE',
  
  // Configuración
  CONFIG_CHANGED: 'CFG_CHANGED',
  SERVICE_STARTED: 'SVC_STARTED',
  SERVICE_STOPPED: 'SVC_STOPPED',
  
  // Seguridad
  ACCESS_DENIED: 'SEC_ACCESS_DENIED',
  RATE_LIMITED: 'SEC_RATE_LIMITED'
};

function audit(event, data) {
  auditLogger.info(event, {
    audit: true,
    timestamp: new Date().toISOString(),
    ...data
  });
}

module.exports = { audit, AuditEvents };
```

### Registro de Decisiones R-P-V

```javascript
// Trazabilidad de decisiones Reasoning-Planning-Verification
const { audit, AuditEvents } = require('../utils/audit');

async function processWithAudit(query, context) {
  const decisionId = `dec-${Date.now()}`;
  
  audit(AuditEvents.DECISION_MADE, {
    decisionId,
    query: query.substring(0, 100),
    reasoning: context.reasoning,
    planning: context.planning,
    verification: context.verification,
    confidence: context.confidence,
    userId: context.userId,
    duration: context.duration
  });
  
  return { decisionId, result: context.result };
}
```

---

## Herramientas de Análisis

### Comandos con pm2 logs

```bash
pm2 logs                    # Ver todos los logs
pm2 logs director           # Logs de un servicio
pm2 logs ejecutor --lines 200 # Últimas N líneas
pm2 logs --err              # Solo errores
pm2 flush                   # Limpiar logs
```

### Análisis con jq (JSON)

```bash
# Filtrar errores
cat logs/director-combined.log | jq 'select(.level == "error")'

# Buscar por requestId
cat logs/*.log | jq 'select(.requestId == "req-123")'

# Contar por nivel
cat logs/ejecutor-combined.log | jq -r '.level' | sort | uniq -c

# Duración promedio
cat logs/ejecutor-combined.log | jq 'select(.duration) | .duration' | \
  awk '{sum+=$1; count++} END {print "Avg:", sum/count, "ms"}'

# Top 10 errores más frecuentes
cat logs/*-error.log | jq -r '.message' | sort | uniq -c | sort -rn | head -10
```

### Análisis con grep, awk

```bash
# Buscar errores de conexión
grep -i "connection.*failed\|ECONNREFUSED" logs/*.log

# Extraer timestamps de errores
grep "error" logs/director-combined.log | awk '{print $1, $2}'

# Contar requests por hora
grep "request" logs/gateway-combined.log | \
  awk '{print substr($1, 1, 13)}' | uniq -c

# Filtrar logs de un usuario
grep "userId.*user-123" logs/*.log
```

### ELK Stack (Opcional)

```yaml
# logstash.conf
input {
  file {
    path => "/opt/openclaw-system/logs/*-combined.log"
    codec => json
    type => "openclaw-system"
  }
}

filter {
  if [type] == "openclaw-system" {
    date {
      match => [ "timestamp", "ISO8601" ]
    }
    mutate {
      add_field => { "cluster" => "openclaw-production" }
    }
  }
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "openclaw-system-%{+YYYY.MM.dd}"
  }
}
```

---

## Alertas basadas en Logs

### Script de Monitoreo

```bash
#!/bin/bash
# scripts/check-logs.sh

ERROR_THRESHOLD=10
SLOW_THRESHOLD=5000

# Verificar errores recientes (últimos 5 minutos)
ERRORS=$(find logs/ -name "*.log" -mmin -5 -exec grep -c "error" {} \; | \
  awk '{sum+=$1} END {print sum}')

if [ "$ERRORS" -gt "$ERROR_THRESHOLD" ]; then
  echo "⚠️ ALERTA: $ERRORS errores en los últimos 5 minutos"
  # Enviar notificación
fi

# Verificar respuestas lentas
SLOW=$(cat logs/ejecutor-combined.log | \
  jq "select(.duration > $SLOW_THRESHOLD)" | wc -l)

if [ "$SLOW" -gt 0 ]; then
  echo "⚠️ ALERTA: $SLOW respuestas lentas detectadas"
fi
```

---

## Exportación para Cumplimiento

### Exportar Logs de Auditoría

```bash
#!/bin/bash
# scripts/export-audit-logs.sh

START_DATE=${1:-$(date -v-30d +%Y-%m-%d)}
END_DATE=${2:-$(date +%Y-%m-%d)}
OUTPUT_DIR="./exports"

mkdir -p "$OUTPUT_DIR"

# Filtrar logs de auditoría por fecha
cat logs/audit-combined.log | \
  jq "select(.timestamp >= \"$START_DATE\" and .timestamp <= \"$END_DATE\")" \
  > "$OUTPUT_DIR/audit-export-$START_DATE-$END_DATE.json"

# Generar resumen
echo "Exportando logs de auditoría:"
echo "  - Desde: $START_DATE"
echo "  - Hasta: $END_DATE"
echo "  - Eventos: $(wc -l < $OUTPUT_DIR/audit-export-*.json)"

# Verificar integridad
sha256sum "$OUTPUT_DIR/audit-export-*.json" > "$OUTPUT_DIR/checksum.sha256"
```

### Formato de Exportación

```json
{
  "export": {
    "cluster": "openclaw-production",
    "startDate": "2026-02-09",
    "endDate": "2026-03-09",
    "generatedAt": "2026-03-09T10:00:00Z",
    "totalEvents": 15420,
    "events": [
      {
        "timestamp": "2026-03-09T14:30:00Z",
        "event": "OP_DECISION_MADE",
        "actor": "user-123",
        "resource": "query-service",
        "result": "success"
      }
    ]
  }
}
```

---

## Referencias Cruzadas

- **[00-gestion-servicios.md](./00-gestion-servicios.md)** - Gestión de PM2 y logs
- **[02-backups.md](./02-backups.md)** - Backup de logs y retención
- **[03-optimizacion.md](./03-optimizacion.md)** - Métricas de rendimiento
- **[../01-SISTEMA/00-arquitectura-maestra.md](../01-SISTEMA/00-arquitectura-maestra.md)** - Arquitectura del sistema
- **[../11-SEGURIDAD/00-seguridad.md](../11-SEGURIDAD/00-seguridad.md)** - Seguridad y cumplimiento

---

> **Documentación relacionada:** Ver [Winston Logger](https://github.com/winstonjs/winston) para configuración avanzada de logging.
