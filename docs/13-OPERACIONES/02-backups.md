# Backups y Restore

**ID:** DOC-OPE-BAC-001
**Versión:** 1.0
**Última actualización:** 2026-03-09
**Cluster:** OPENCLAW-system OpenClaw

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [Estrategia de Backup](#estrategia-de-backup)
3. [Frecuencia de Backups](#frecuencia-de-backups)
4. [Tipos de Backup](#tipos-de-backup)
5. [Herramientas de Backup](#herramientas-de-backup)
6. [Procedimiento de Restore](#procedimiento-de-restore)
7. [Testing de Backups](#testing-de-backups)
8. [Retención y Almacenamiento](#retención-y-almacenamiento)
9. [Automatización con Cron](#automatización-con-cron)
10. [Referencias Cruzadas](#referencias-cruzadas)

---

## Introducción

La estrategia de backup del OPENCLAW-system está diseñada para garantizar la recuperación ante desastres, protección de datos críticos del Vault del Archivador, y cumplimiento de políticas de retención. Se implementan múltiples niveles de backup según la criticidad de los datos.

### Componentes a Respaldar

```
┌─────────────────────────────────────────────────────────────┐
│                   Componentes de Backup                     │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐   ┌─────────────────┐                │
│  │  Configuración  │   │   Vault (MD)    │                │
│  │  ~/.openclaw/   │   │   ./vault/      │                │
│  │  Prioridad: Alta│   │  Prioridad: Alta│                │
│  └─────────────────┘   └─────────────────┘                │
│                                                             │
│  ┌─────────────────┐   ┌─────────────────┐                │
│  │  Bases de Datos │   │      Logs       │                │
│  │  SQLite/LanceDB │   │   ./logs/       │                │
│  │  Prioridad: Alta│   │ Prioridad: Media│                │
│  └─────────────────┘   └─────────────────┘                │
│                                                             │
│  ┌─────────────────┐                                        │
│  │  Temporales     │                                        │
│  │  Caché Temporal │                                        │
│  │ Prioridad: Baja │                                        │
│  └─────────────────┘                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## Estrategia de Backup

### Objetivos de Recuperación (SLA)

| Métrica | Valor | Descripción |
|---------|-------|-------------|
| **RTO (Recovery Time Objective)** | 4 horas | Tiempo máximo para restaurar el sistema operativo |
| **RPO (Recovery Point Objective)** | 24 horas | Pérdida máxima de datos tolerable |
| **MTTR (Mean Time To Recovery)** | < 2 horas | Tiempo promedio de recuperación |

### Política 3-2-1

El OPENCLAW-system sigue la estrategia **3-2-1** de backups:

| Regla | Descripción | Implementación |
|-------|-------------|----------------|
| **3 copias** | Tres versiones de datos | Principal + 2 backups |
| **2 medios** | Dos tipos de almacenamiento | Disco local + Nube (S3/Drive) |
| **1 offsite** | Una copia fuera del sitio | rclone a almacenamiento cloud |

### Datos Críticos por Engranaje

| Componente | Ubicación | Frecuencia | Retención |
|------------|-----------|------------|-----------|
| Config Manager | `~/.openclaw/manager/` | Diario | 30 días |
| Vault Archivador | `./vault/` | Diario | 90 días |
| SQLite Metadata | `./data/cko.db` | Diario | 30 días |
| LanceDB Embeddings | `./data/lancedb/` | Semanal | 90 días |
| Logs | `./logs/` | Diario | 30 días |

---

## Frecuencia de Backups

### Calendario de Backups

```
DIARIO (00:00)
├── Vault del Archivador (.md files)
├── Logs del sistema
├── Configuraciones (~/.openclaw/)
└── SQLite metadata

SEMANAL (Domingo 02:00)
├── Backup completo de BD
├── LanceDB embeddings
└── Configuraciones + dependencias

MENSUAL (1er Domingo 03:00)
├── Backup completo del sistema
├── Archivos temporales del Ejecutor
└── Export de métricas históricas
```

---

## Tipos de Backup

### Backup Incremental (Diario)

```bash
#!/bin/bash
# scripts/backup-incremental.sh

BACKUP_DIR="/opt/openclaw-system/backups/incremental"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%H%M%S)

# Backup incremental con rsync
rsync -av --delete \
  --link-dest="$BACKUP_DIR/latest" \
  ./vault/ "$BACKUP_DIR/$DATE-$TIMESTAMP/vault/"

# Actualizar link simbólico
ln -sfn "$BACKUP_DIR/$DATE-$TIMESTAMP" "$BACKUP_DIR/latest"

echo "✅ Backup incremental completado: $DATE-$TIMESTAMP"
```

### Backup Diferencial (Semanal)

```bash
#!/bin/bash
# scripts/backup-differential.sh

BACKUP_DIR="/opt/openclaw-system/backups/differential"
FULL_BACKUP="/opt/openclaw-system/backups/full/latest"
DATE=$(date +%Y-%m-%d)

rsync -av --delete \
  --compare-dest="$FULL_BACKUP" \
  ./data/ "$BACKUP_DIR/$DATE/"

echo "✅ Backup diferencial completado: $DATE"
```

### Backup Completo (Mensual)

```bash
#!/bin/bash
# scripts/backup-full.sh

BACKUP_DIR="/opt/openclaw-system/backups/full"
DATE=$(date +%Y-%m-%d)

mkdir -p "$BACKUP_DIR/$DATE"

# Backup completo
rsync -av ./vault/ "$BACKUP_DIR/$DATE/vault/"
rsync -av ./data/ "$BACKUP_DIR/$DATE/data/"
rsync -av ./logs/ "$BACKUP_DIR/$DATE/logs/"
rsync -av ~/.openclaw/ "$BACKUP_DIR/$DATE/config/"

# Comprimir
tar -czf "$BACKUP_DIR/$DATE.tar.gz" -C "$BACKUP_DIR" "$DATE"
rm -rf "$BACKUP_DIR/$DATE"

# Actualizar link
ln -sfn "$BACKUP_DIR/$DATE.tar.gz" "$BACKUP_DIR/latest"

echo "✅ Backup completo completado: $DATE.tar.gz"
```

---

## Herramientas de Backup

### rsync (Local)

```bash
# Sincronización local
rsync -av --progress --delete \
  --exclude='*.tmp' \
  --exclude='node_modules' \
  ./vault/ /backup/openclaw-system/vault/

# Sincronización remota via SSH
rsync -avz -e "ssh -p 22" \
  ./vault/ user@backup-server:/backups/openclaw-system/vault/
```

### tar.gz (Compresión)

```bash
# Crear backup comprimido
tar -czvf backup-$(date +%Y%m%d).tar.gz \
  --exclude='*.log' \
  --exclude='node_modules' \
  ./vault/ ./data/

# Verificar integridad
gzip -t backup.tar.gz
```

### rclone (Cloud Storage)

```bash
# Configurar rclone
rclone config

# Sincronizar a S3
rclone sync ./vault/ s3:openclaw-system-backups/vault/ \
  --progress \
  --transfers 4

# Sincronizar a Google Drive
rclone sync ./backups/full/ gdrive:openclaw-system-backups/full/ \
  --progress

# Sincronizar con encriptación
rclone crypt /local/path remote:encrypted-backups \
  --password-command "cat ~/.rclone-password"
```

### Duplicity (Encriptado)

```bash
# Backup encriptado incremental
duplicity incremental \
  --full-if-older-than 30D \
  --encrypt-key GPG_KEY_ID \
  ./vault/ \
  s3://s3.amazonaws.com/openclaw-system-backups/vault/

# Restaurar desde backup encriptado
duplicity restore \
  --decrypt-key GPG_KEY_ID \
  s3://s3.amazonaws.com/openclaw-system-backups/vault/ \
  ./vault-restored/

# Verificar backups
duplicity verify \
  s3://s3.amazonaws.com/openclaw-system-backups/vault/ \
  ./vault/
```

---

## Procedimiento de Restore

### Restauración del Vault

```bash
#!/bin/bash
# scripts/restore-vault.sh

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
  echo "Uso: $0 <backup-file>"
  echo "Backups disponibles:"
  ls -la /opt/openclaw-system/backups/full/*.tar.gz
  exit 1
fi

echo "🔄 Restaurando Vault desde $BACKUP_FILE"

# Detener Archivador
pm2 stop archivador

# Backup del estado actual
mv ./vault "./vault.backup.$(date +%Y%m%d%H%M%S)"

# Restaurar
tar -xzf "$BACKUP_FILE" -C ./ vault/

# Verificar integridad
if [ -d "./vault" ]; then
    echo "✅ Vault restaurado correctamente"
    pm2 start archivador
else
    echo "❌ Error en la restauración"
    exit 1
fi
```

### Restauración de Configuraciones

```bash
#!/bin/bash
# scripts/restore-config.sh

BACKUP_DIR=$1

echo "🔄 Restaurando configuraciones desde $BACKUP_DIR"

pm2 stop all

rsync -av "$BACKUP_DIR/config/" ~/.openclaw/
cp "$BACKUP_DIR/ecosystem.config.js" ./

pm2 start ecosystem.config.js

echo "✅ Configuraciones restauradas"
```

### Restauración de Base de Datos

```bash
#!/bin/bash
# scripts/restore-database.sh

BACKUP_FILE=$1
DB_PATH="./data/cko.db"

echo "🔄 Restaurando base de datos desde $BACKUP_FILE"

if [ -f "$DB_PATH" ]; then
    mv "$DB_PATH" "${DB_PATH}.backup"
fi

if [[ "$BACKUP_FILE" == *.tar.gz ]]; then
    tar -xzf "$BACKUP_FILE" -C ./data/
else
    cp "$BACKUP_FILE" "$DB_PATH"
fi

# Verificar integridad SQLite
sqlite3 "$DB_PATH" "PRAGMA integrity_check;"

if [ $? -eq 0 ]; then
    echo "✅ Base de datos restaurada correctamente"
else
    echo "❌ Error: Base de datos corrupta"
    exit 1
fi
```

### Restauración Completa del Sistema

```bash
#!/bin/bash
# scripts/restore-full.sh

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
    echo "Uso: $0 <backup-file.tar.gz>"
    exit 1
fi

echo "⚠️ RESTAURACIÓN COMPLETA DEL SISTEMA"
read -p "¿Continuar? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Operación cancelada"
    exit 0
fi

pm2 stop all
pm2 delete all

TEMP_DIR=$(mktemp -d)
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

echo "📦 Restaurando Vault..."
rsync -av "$TEMP_DIR/vault/" ./vault/

echo "📦 Restaurando datos..."
rsync -av "$TEMP_DIR/data/" ./data/

echo "📦 Restaurando configuraciones..."
rsync -av "$TEMP_DIR/config/" ~/.openclaw/

pm2 start ecosystem.config.js

rm -rf "$TEMP_DIR"
echo "✅ Restauración completa finalizada"
```

---

## Testing de Backups

### Test Mensual Automatizado

```bash
#!/bin/bash
# scripts/test-backup.sh

BACKUP_FILE="/opt/openclaw-system/backups/full/latest"
TEST_DIR="/tmp/backup-test-$(date +%Y%m%d)"

echo "🧪 Iniciando test de backup"

mkdir -p "$TEST_DIR"
tar -xzf "$BACKUP_FILE" -C "$TEST_DIR"

# Verificar estructura
echo "📋 Verificando estructura..."
REQUIRED_DIRS=("vault" "data" "config")
for DIR in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$TEST_DIR/$DIR" ]; then
        echo "❌ Falta directorio: $DIR"
        exit 1
    fi
done

# Verificar SQLite
echo "📋 Verificando base de datos..."
sqlite3 "$TEST_DIR/data/cko.db" "PRAGMA integrity_check;"

# Verificar archivos del Vault
echo "📋 Verificando Vault..."
VAULT_FILES=$(find "$TEST_DIR/vault" -name "*.md" | wc -l)
echo "Archivos MD en Vault: $VAULT_FILES"

BACKUP_SIZE=$(du -sh "$TEST_DIR" | cut -f1)
echo "Tamaño del backup: $BACKUP_SIZE"

rm -rf "$TEST_DIR"
echo "✅ Test de backup completado exitosamente"
```

### Validación de Integridad

```bash
#!/bin/bash
# scripts/verify-backup.sh

BACKUP_DIR="/opt/openclaw-system/backups"

echo "🔍 Verificando checksums..."
find "$BACKUP_DIR" -name "*.sha256" | while read CHECKSUM_FILE; do
    DIR=$(dirname "$CHECKSUM_FILE")
    cd "$DIR"
    sha256sum -c "$CHECKSUM_FILE"
done

echo "🔍 Verificando archivos comprimidos..."
find "$BACKUP_DIR" -name "*.tar.gz" | while read ARCHIVE; do
    gzip -t "$ARCHIVE" && echo "✅ $ARCHIVE OK"
done
```

---

## Retención y Almacenamiento

### Política de Retención

```
INCREMENTALES
├── Retención: 7 días
└── Cantidad máxima: 7

DIFERENCIALES
├── Retención: 30 días
└── Cantidad máxima: 4

COMPLETOS
├── Retención: 90 días
└── Cantidad máxima: 3

CLOUD (Offsite)
├── Retención: 1 año
└── Versionado: Habilitado
```

### Limpieza Automática

```bash
#!/bin/bash
# scripts/cleanup-backups.sh

BACKUP_DIR="/opt/openclaw-system/backups"

echo "🧹 Limpiando backups antiguos..."

# Incrementales: 7 días
find "$BACKUP_DIR/incremental" -type d -mtime +7 -exec rm -rf {} +

# Diferenciales: 30 días
find "$BACKUP_DIR/differential" -type d -mtime +30 -exec rm -rf {} +

# Completos: 90 días
find "$BACKUP_DIR/full" -name "*.tar.gz" -mtime +90 -delete

# Logs de backup: 30 días
find "$BACKUP_DIR" -name "*.log" -mtime +30 -delete

echo "✅ Limpieza completada"
```

---

## Automatización con Cron

### Configuración de Crontab

```bash
# Editar crontab
crontab -e

# Agregar tareas de backup
# Backup incremental diario a medianoche
0 0 * * * /opt/openclaw-system/scripts/backup-incremental.sh >> /var/log/openclaw-backup.log 2>&1

# Backup diferencial semanal (domingo 2am)
0 2 * * 0 /opt/openclaw-system/scripts/backup-differential.sh >> /var/log/openclaw-backup.log 2>&1

# Backup completo mensual (1er domingo 3am)
0 3 1-7 * 0 [ "$(date +\%w)" = "0" ] && /opt/openclaw-system/scripts/backup-full.sh >> /var/log/openclaw-backup.log 2>&1

# Sincronización cloud diaria
0 4 * * * /opt/openclaw-system/scripts/sync-cloud.sh >> /var/log/openclaw-backup.log 2>&1

# Test mensual
0 5 15 * * /opt/openclaw-system/scripts/test-backup.sh >> /var/log/openclaw-backup-test.log 2>&1

# Limpieza semanal
0 6 * * 0 /opt/openclaw-system/scripts/cleanup-backups.sh >> /var/log/openclaw-backup.log 2>&1
```

### Script de Sincronización Cloud

```bash
#!/bin/bash
# scripts/sync-cloud.sh

echo "☁️ Sincronizando backups a la nube..."

# Sincronizar a S3
rclone sync /opt/openclaw-system/backups/full/ \
  s3:openclaw-system-backups/full/ \
  --progress \
  --transfers 4

# Sincronizar a Google Drive (backup secundario)
rclone sync /opt/openclaw-system/backups/full/ \
  gdrive:openclaw-system-backups/full/ \
  --progress

echo "✅ Sincronización completada"
```

---

## Referencias Cruzadas

- **[00-gestion-servicios.md](./00-gestion-servicios.md)** - Gestión de servicios PM2
- **[01-logs-auditoria.md](./01-logs-auditoria.md)** - Sistema de logs y auditoría
- **[03-optimizacion.md](./03-optimizacion.md)** - Optimización de rendimiento
- **[../01-SISTEMA/00-arquitectura-maestra.md](../01-SISTEMA/00-arquitectura-maestra.md)** - Arquitectura del sistema
- **[../12-IMPLEMENTACION/03-despliegue.md](../12-IMPLEMENTACION/03-despliegue.md)** - Despliegue en producción

---

> **Documentación relacionada:** Ver [rsync documentation](https://rsync.samba.org/documentation.html) y [rclone docs](https://rclone.org/docs/) para configuración avanzada.
