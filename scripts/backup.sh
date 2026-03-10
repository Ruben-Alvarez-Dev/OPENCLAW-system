#!/bin/bash
#
# backup.sh - Script de backup para OPENCLAW-system
#
# Uso: ./backup.sh
#
# Este script crea backups de:
# - Base de datos Redis
# - Configuracion del sistema
# - Limpia backups antiguos (>30 dias)
#
# Personaliza las variables segun tu instalacion:
# - BACKUP_DIR: Directorio donde guardar los backups
# - REDIS_DUMP_PATH: Ruta al dump.rdb de Redis
# - OPENCLAW_ROOT: Directorio raiz de OPENCLAW
#

# ==============================================================================
# CONFIGURACION - PERSONALIZA ESTAS VARIABLES
# ==============================================================================

# Directorio de backups (cambiar segun tu instalacion)
# M1 Mac Mini: /Volumes/NVMe-4TB/openclaw/backups
# VPS: /opt/openclaw/backups
BACKUP_DIR="${OPENCLAW_ROOT:-/opt/openclaw}/backups"

# Ruta al dump de Redis
# macOS Homebrew: /opt/homebrew/var/db/redis/dump.rdb
# Linux: /var/lib/redis/dump.rdb
REDIS_DUMP_PATH="/opt/homebrew/var/db/redis/dump.rdb"

# Directorio raiz de OPENCLAW
OPENCLAW_ROOT="${OPENCLAW_ROOT:-/opt/openclaw}"

# Dias a mantener backups
RETENTION_DAYS=30

# ==============================================================================
# EJECUCION - NO MODIFICAR A MENOS QUE SEPAS LO QUE HACES
# ==============================================================================

set -e

DATE=$(date +%Y%m%d_%H%M%S)

echo "=========================================="
echo "OPENCLAW Backup Script"
echo "Fecha: $(date)"
echo "=========================================="

# Crear directorio de backups si no existe
mkdir -p "$BACKUP_DIR"

# Backup Redis
echo "[1/3] Backup de Redis..."
if command -v redis-cli &> /dev/null; then
    redis-cli BGSAVE
    sleep 2  # Esperar a que termine el BGSAVE

    if [ -f "$REDIS_DUMP_PATH" ]; then
        cp "$REDIS_DUMP_PATH" "$BACKUP_DIR/redis_$DATE.rdb"
        echo "  Redis backup: redis_$DATE.rdb"
    else
        echo "  ADVERTENCIA: No se encontro dump.rdb en $REDIS_DUMP_PATH"
    fi
else
    echo "  ADVERTENCIA: redis-cli no encontrado, saltando backup Redis"
fi

# Backup configuracion
echo "[2/3] Backup de configuracion..."
if [ -d "$OPENCLAW_ROOT" ]; then
    tar -czf "$BACKUP_DIR/config_$DATE.tar.gz" \
        --exclude='node_modules' \
        --exclude='.next' \
        --exclude='dist' \
        --exclude='build' \
        --exclude='.git' \
        -C "$OPENCLAW_ROOT" \
        . 2>/dev/null || echo "  ADVERTENCIA: Algunos archivos no pudieron ser backup"

    echo "  Config backup: config_$DATE.tar.gz"
else
    echo "  ADVERTENCIA: Directorio OPENCLAW_ROOT no encontrado"
fi

# Limpiar backups antiguos
echo "[3/3] Limpiando backups antiguos (>$RETENTION_DAYS dias)..."
DELETED_COUNT=$(find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -delete -print | wc -l)
echo "  Eliminados: $DELETED_COUNT archivos antiguos"

# Resumen
echo ""
echo "=========================================="
echo "Backup completado: $DATE"
echo "Ubicacion: $BACKUP_DIR"
echo "=========================================="

# Listar ultimos backups
echo ""
echo "Ultimos backups:"
ls -lt "$BACKUP_DIR" | head -n 10
