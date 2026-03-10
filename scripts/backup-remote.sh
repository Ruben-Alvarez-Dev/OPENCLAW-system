#!/bin/bash
#
# backup-remote.sh - Sincroniza backups a servidor remoto
#
# Uso: ./backup-remote.sh
#
# Este script:
# 1. Ejecuta backup local primero
# 2. Sincroniza backups al servidor remoto via rsync/ssh
#
# Requisitos:
# - SSH configurado con claves (sin password)
# - rsync instalado en ambos servidores
#
# Personaliza las variables segun tu configuracion:
#

# ==============================================================================
# CONFIGURACION - PERSONALIZA ESTAS VARIABLES
# ==============================================================================

# IP del servidor remoto (VPS)
REMOTE_HOST="TU_VPS_IP"  # Cambiar por IP real

# Usuario SSH en el servidor remoto
REMOTE_USER="openclaw"

# Directorio local de backups
LOCAL_BACKUP_DIR="${OPENCLAW_ROOT:-/Volumes/NVMe-4TB/openclaw}/backups"

# Directorio remoto donde guardar los backups
REMOTE_BACKUP_DIR="/opt/openclaw/backups/macmini"

# Script de backup local (ruta absoluta)
LOCAL_BACKUP_SCRIPT="${OPENCLAW_ROOT:-/Volumes/NVMe-4TB/openclaw}/scripts/backup.sh"

# Clave SSH (opcional, por defecto usa ~/.ssh/id_rsa)
SSH_KEY="$HOME/.ssh/id_rsa"

# ==============================================================================
# EJECUCION - NO MODIFICAR A MENOS QUE SEPAS LO QUE HACES
# ==============================================================================

set -e

DATE=$(date +%Y%m%d_%H%M%S)

echo "=========================================="
echo "OPENCLAW Remote Backup Script"
echo "Fecha: $(date)"
echo "=========================================="

# Verificar configuracion
if [ "$REMOTE_HOST" = "TU_VPS_IP" ]; then
    echo "ERROR: Debes configurar REMOTE_HOST en este script"
    exit 1
fi

# Paso 1: Backup local
echo "[1/2] Ejecutando backup local..."
if [ -x "$LOCAL_BACKUP_SCRIPT" ]; then
    "$LOCAL_BACKUP_SCRIPT"
else
    echo "  ADVERTENCIA: Script de backup local no encontrado o no ejecutable"
    echo "  Continuando solo con sync..."
fi

# Paso 2: Sync al servidor remoto
echo "[2/2] Sincronizando al servidor remoto..."

# Verificar conectividad SSH
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" "echo ok" &>/dev/null; then
    echo "ERROR: No se puede conectar a $REMOTE_USER@$REMOTE_HOST"
    echo "Verifica:"
    echo "  1. La IP es correcta"
    echo "  2. SSH esta configurado con claves"
    echo "  3. El usuario '$REMOTE_USER' existe en el remoto"
    exit 1
fi

# Crear directorio remoto si no existe
ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_BACKUP_DIR"

# Sincronizar via rsync
rsync -avz --delete \
    -e "ssh -i $SSH_KEY" \
    "$LOCAL_BACKUP_DIR/" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_BACKUP_DIR/"

echo ""
echo "=========================================="
echo "Backup remoto completado: $DATE"
echo "Origen:  $LOCAL_BACKUP_DIR"
echo "Destino: $REMOTE_USER@$REMOTE_HOST:$REMOTE_BACKUP_DIR"
echo "=========================================="
