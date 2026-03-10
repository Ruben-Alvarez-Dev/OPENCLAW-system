# Configuración de Redis

**ID:** DOC-SIS-RED-001
**Versión:** 1.0
**Fecha:** 2026-03-10
**Estado:** Documentación Técnica

---

## Resumen

Redis se utiliza en OPENCLAW-system como bus de mensajes, cache de sesiones y almacén de estado temporal para PM2 Cluster.

---

## 1. Modos de Uso

| Modo | Propósito | Requisito |
|------|-----------|-----------|
| **Bus de Mensajes** | Comunicación inter-agentes en cluster | PM2 cluster mode |
| **Cache de Sesiones** | Almacenar sesiones de usuario | Opcional |
| **Rate Limiting** | Control de velocidad de requests | Recomendado |
| **Lock Distribuido** | Coordinación entre instancias | Cluster mode |

---

## 2. Instalación

### 2.1 Ubuntu/Debian

```bash
# Instalar Redis
sudo apt update
sudo apt install -y redis-server

# Verificar versión
redis-server --version
# Debe ser >= 7.0

# Iniciar servicio
sudo systemctl enable redis-server
sudo systemctl start redis-server

# Verificar
redis-cli ping
# Esperado: PONG
```

### 2.2 macOS (Homebrew)

```bash
# Instalar Redis
brew install redis

# Iniciar servicio
brew services start redis

# Verificar
redis-cli ping
```

### 2.3 Docker

```bash
# Contenedor Redis
docker run -d \
  --name openclaw-redis \
  -p 127.0.0.1:6379:6379 \
  -v openclaw_redis_data:/data \
  redis:7-alpine \
  redis-server --appendonly yes

# Verificar
docker exec openclaw-redis redis-cli ping
```

---

## 3. Configuración

### 3.1 Archivo de Configuración

```bash
# /etc/redis/redis.conf (Ubuntu)
# /opt/homebrew/etc/redis.conf (macOS)

# Configuración para OPENCLAW-system:

# Red
bind 127.0.0.1
port 6379
protected-mode yes

# Memoria
maxmemory 512mb
maxmemory-policy allkeys-lru

# Persistencia AOF
appendonly yes
appendfsync everysec
appendfilename "appendonly.aof"

# Persistencia RDB (snapshots)
save 900 1
save 300 10
save 60 10000

# Logs
loglevel notice
logfile /var/log/redis/redis-server.log

# Seguridad
requirepass ${REDIS_PASSWORD}

# Límites
tcp-backlog 511
tcp-keepalive 300
timeout 0

# Performance
disable-thp yes
```

### 3.2 Configuración por Entorno

```bash
# Crear configuración específica
sudo cp /etc/redis/redis.conf /etc/redis/redis-openclaw.conf

# Editar
sudo nano /etc/redis/redis-openclaw.conf
```

```conf
# /etc/redis/redis-openclaw.conf

# === OPENCLAW-SYSTEM ===
# Configuración optimizada para multi-agente

# Bind solo localhost
bind 127.0.0.1 ::1

# Puerto estándar
port 6379

# Memoria máxima (ajustar según RAM disponible)
maxmemory 1gb

# Política de eviction
maxmemory-policy volatile-lru

# AOF para durabilidad
appendonly yes
appendfsync everysec
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# RDB para backups
save 900 1
save 300 10
save 60 10000
dbfilename dump-openclaw.rdb
dir /var/lib/redis

# Timeout para conexiones idle
timeout 300

# Máximo de clientes
maxclients 10000

# Logs
loglevel notice
logfile /var/log/redis/redis-openclaw.log

# Slow log
slowlog-log-slower-than 10000
slowlog-max-len 128

# Seguridad - contraseña
# Generar con: openssl rand -hex 32
requirepass TU_CONTRASEÑA_SEGURA_AQUI
```

---

## 4. Autenticación

### 4.1 Configurar Contraseña

```bash
# Generar contraseña segura
REDIS_PASSWORD=$(openssl rand -hex 32)
echo "REDIS_PASSWORD=$REDIS_PASSWORD"

# Añadir a configuración
sudo sed -i "s/# requirepass foobared/requirepass $REDIS_PASSWORD/" /etc/redis/redis-openclaw.conf

# Guardar en .env
echo "REDIS_PASSWORD=$REDIS_PASSWORD" >> ~/.openclaw/config/.env

# Reiniciar Redis
sudo systemctl restart redis-server
```

### 4.2 Configurar ACL (Redis 6+)

```bash
# Crear usuario específico para OPENCLAW
redis-cli -a $REDIS_PASSWORD

> ACL SETUSER openclaw on +@all -@dangerous >TU_PASSWORD >~* &*
> ACL SAVE
```

### 4.3 Variables de Entorno

```bash
# ~/.openclaw/config/.env

# Redis
REDIS_URL=redis://127.0.0.1:6379
REDIS_PASSWORD=TU_CONTRASEÑA_SEGURA

# Para PM2 Cluster
PM2_CLUSTER_MODE=true
```

---

## 5. Persistencia

### 5.1 RDB Snapshots

```bash
# Configurar en redis.conf
save 900 1      # Snapshot después de 1 cambio en 900s
save 300 10     # Snapshot después de 10 cambios en 300s
save 60 10000   # Snapshot después de 10000 cambios en 60s

# Ubicación
dbfilename dump-openclaw.rdb
dir /var/lib/redis

# Backup manual
redis-cli -a $REDIS_PASSWORD BGSAVE
cp /var/lib/redis/dump-openclaw.rdb /backup/redis/dump-$(date +%Y%m%d).rdb
```

### 5.2 AOF (Append-Only File)

```bash
# Configuración AOF
appendonly yes
appendfsync everysec     # Compromiso entre rendimiento y durabilidad
appendfilename "appendonly.aof"

# Rewrite automático
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# Reparar AOF corrupto
redis-check-aof --fix /var/lib/redis/appendonly.aof
```

### 5.3 Estrategia Híbrida

```bash
# Usar ambas persistencias
# RDB: Snapshots periódicos para recuperación rápida
# AOF: Cada segundo para mínima pérdida de datos

# Configurar ambas
appendonly yes
save 900 1
save 300 10
save 60 10000
```

---

## 6. Integración con PM2 Cluster

### 6.1 Configuración de PM2

```javascript
// ecosystem.config.js con Redis para cluster

module.exports = {
  apps: [
    {
      name: 'sis-ejecutor',
      script: 'dist/cli/openclaw.js',
      args: 'gear start ejecutor --gateway ws://127.0.0.1:18789',
      instances: 4,           // Múltiples instancias
      exec_mode: 'cluster',   // Modo cluster
      env: {
        REDIS_URL: 'redis://127.0.0.1:6379',
        REDIS_PASSWORD: process.env.REDIS_PASSWORD
      }
    }
  ]
};
```

### 6.2 Socket.io con Redis Adapter

```typescript
// src/gateway/redis-adapter.ts
import { createAdapter } from '@socket.io/redis-adapter';
import { createClient } from 'redis';

const pubClient = createClient({
  url: process.env.REDIS_URL,
  password: process.env.REDIS_PASSWORD
});

const subClient = pubClient.duplicate();

await Promise.all([
  pubClient.connect(),
  subClient.connect()
]);

io.adapter(createAdapter(pubClient, subClient));
```

---

## 7. Monitoreo

### 7.1 Comandos de Estado

```bash
# Info general
redis-cli -a $REDIS_PASSWORD INFO

# Info de memoria
redis-cli -a $REDIS_PASSWORD INFO memory

# Info de persistencia
redis-cli -a $REDIS_PASSWORD INFO persistence

# Clientes conectados
redis-cli -a $REDIS_PASSWORD CLIENT LIST

# Estadísticas
redis-cli -a $REDIS_PASSWORD --stat

# Monitor en tiempo real
redis-cli -a $REDIS_PASSWORD MONITOR

# Slow log
redis-cli -a $REDIS_PASSWORD SLOWLOG GET 10
```

### 7.2 Métricas Clave

| Métrica | Comando | Valor Saludable |
|---------|---------|-----------------|
| Memoria usada | `INFO memory` | < 80% maxmemory |
| Conexiones | `INFO clients` | < maxclients |
| Ops/seg | `INFO stats` | Depende de uso |
| Hits/Misses | `INFO stats` | > 90% hits |
| Latencia | `--latency` | < 1ms |

### 7.3 Script de Monitoreo

```bash
#!/bin/bash
# scripts/redis-health.sh

source ~/.openclaw/config/.env

echo "=== REDIS HEALTH CHECK ==="
echo ""

echo "1. Conectividad:"
redis-cli -a $REDIS_PASSWORD ping

echo ""
echo "2. Memoria:"
redis-cli -a $REDIS_PASSWORD INFO memory | grep -E "used_memory_human|maxmemory_human"

echo ""
echo "3. Clientes:"
redis-cli -a $REDIS_PASSWORD INFO clients | grep connected_clients

echo ""
echo "4. Persistencia:"
redis-cli -a $REDIS_PASSWORD INFO persistence | grep -E "rdb_last_save_time|aof_enabled"

echo ""
echo "5. Estadísticas:"
redis-cli -a $REDIS_PASSWORD INFO stats | grep -E "total_commands_processed|keyspace_hits|keyspace_misses"
```

---

## 8. Backup y Restauración

### 8.1 Backup Automatizado

```bash
#!/bin/bash
# scripts/redis-backup.sh

BACKUP_DIR="/backup/redis"
DATE=$(date +%Y%m%d_%H%M%S)

# Crear directorio
mkdir -p $BACKUP_DIR

# Forzar RDB snapshot
redis-cli -a $REDIS_PASSWORD BGSAVE

# Esperar a que termine
sleep 5

# Copiar archivos
cp /var/lib/redis/dump-openclaw.rdb $BACKUP_DIR/dump-$DATE.rdb
cp /var/lib/redis/appendonly.aof $BACKUP_DIR/aof-$DATE.aof 2>/dev/null || true

# Comprimir
tar -czf $BACKUP_DIR/redis-backup-$DATE.tar.gz -C $BACKUP_DIR dump-$DATE.rdb

# Limpiar backups antiguos (>7 días)
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completado: redis-backup-$DATE.tar.gz"
```

### 8.2 Restaurar

```bash
#!/bin/bash
# scripts/redis-restore.sh

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
  echo "Uso: $0 <backup-file.tar.gz>"
  exit 1
fi

# Detener Redis
sudo systemctl stop redis-server

# Extraer backup
tar -xzf $BACKUP_FILE -C /var/lib/redis/

# Renombrar a nombre correcto
mv /var/lib/redis/dump-*.rdb /var/lib/redis/dump-openclaw.rdb

# Iniciar Redis
sudo systemctl start redis-server

# Verificar
redis-cli -a $REDIS_PASSWORD ping
```

---

## 9. Troubleshooting

### 9.1 Redis No Inicia

```bash
# Verificar logs
sudo tail -f /var/log/redis/redis-server.log

# Verificar permisos
sudo chown -R redis:redis /var/lib/redis
sudo chmod 750 /var/lib/redis

# Verificar configuración
redis-server /etc/redis/redis-openclaw.conf --test-memory 100
```

### 9.2 Memoria Llena

```bash
# Ver uso
redis-cli -a $REDIS_PASSWORD INFO memory | grep used_memory_human

# Ver claves grandes
redis-cli -a $REDIS_PASSWORD --bigkeys

# Limpiar claves con TTL expirado
redis-cli -a $REDIS_PASSWORD DEBUG SLEEP 0.1

# Forzar eviction
redis-cli -a $REDIS_PASSWORD MEMORY PURGE
```

### 9.3 Alta Latencia

```bash
# Verificar slow log
redis-cli -a $REDIS_PASSWORD SLOWLOG GET 20

# Verificar comandos lentos
redis-cli -a $REDIS_PASSWORD --latency

# Deshabilitar THP
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
```

---

## 10. Checklist de Configuración

```markdown
## Instalación
- [ ] Redis >= 7.0 instalado
- [ ] Servicio iniciado y habilitado
- [ ] `redis-cli ping` responde PONG

## Seguridad
- [ ] Bind solo a 127.0.0.1
- [ ] Contraseña configurada
- [ ] ACL configurado (opcional)
- [ ] Firewall permite solo localhost

## Persistencia
- [ ] AOF habilitado
- [ ] RDB configurado
- [ ] Backups automatizados

## Performance
- [ ] maxmemory configurado
- [ ] Política de eviction definida
- [ ] THP deshabilitado

## Monitoreo
- [ ] Script de health check
- [ ] Alertas de memoria
- [ ] Logs rotativos
```

---

**Documento:** Configuración de Redis
**ID:** DOC-SIS-RED-001
**Versión:** 1.0
**Fecha:** 2026-03-10
