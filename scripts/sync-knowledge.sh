#!/bin/bash
#
# sync-knowledge.sh - Sincroniza la base de conocimiento con servidor remoto
#
# Uso: ./sync-knowledge.sh [push|pull]
#
# Comandos:
#   push (default) - Envia cambios locales al remoto
#   pull           - Trae cambios del remoto al local
#
# Este script sincroniza:
# - Documentos de conocimiento
# - Vectores LanceDB
# - Archivos de entrenamiento
#
# Requisitos:
# - SSH configurado con claves (sin password)
# - rsync instalado en ambos servidores
#

# ==============================================================================
# CONFIGURACION - PERSONALIZA ESTAS VARIABLES
# ==============================================================================

# IP del servidor remoto (VPS)
REMOTE_HOST="TU_VPS_IP"  # Cambiar por IP real

# Usuario SSH en el servidor remoto
REMOTE_USER="openclaw"

# Directorio local de conocimiento
LOCAL_KNOWLEDGE_DIR="${OPENCLAW_ROOT:-/Volumes/NVMe-4TB/openclaw}/conocimiento"

# Directorio remoto de conocimiento
REMOTE_KNOWLEDGE_DIR="/opt/openclaw/conocimiento"

# Clave SSH (opcional, por defecto usa ~/.ssh/id_rsa)
SSH_KEY="$HOME/.ssh/id_rsa"

# Directorios a excluir del sync
EXCLUDE_PATTERNS=(
    "*.tmp"
    "*.log"
    ".DS_Store"
    "__pycache__"
    "node_modules"
)

# ==============================================================================
# EJECUCION - NO MODIFICAR A MENOS QUE SEPAS LO QUE HACES
# ==============================================================================

set -e

COMMAND="${1:-push}"
DATE=$(date +%Y%m%d_%H%M%S)

echo "=========================================="
echo "OPENCLAW Knowledge Sync"
echo "Fecha: $(date)"
echo "Comando: $COMMAND"
echo "=========================================="

# Verificar configuracion
if [ "$REMOTE_HOST" = "TU_VPS_IP" ]; then
    echo "ERROR: Debes configurar REMOTE_HOST en este script"
    exit 1
fi

# Construir argumentos exclude
EXCLUDE_ARGS=""
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude=$pattern"
done

# Verificar conectividad SSH
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" "echo ok" &>/dev/null; then
    echo "ERROR: No se puede conectar a $REMOTE_USER@$REMOTE_HOST"
    echo "Verifica:"
    echo "  1. La IP es correcta"
    echo "  2. SSH esta configurado con claves"
    echo "  3. El usuario '$REMOTE_USER' existe en el remoto"
    exit 1
fi

# Crear directorios si no existen
mkdir -p "$LOCAL_KNOWLEDGE_DIR"
ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_KNOWLEDGE_DIR"

case "$COMMAND" in
    push)
        echo "Enviando conocimiento al servidor remoto..."

        # Dry run primero para ver cambios
        echo ""
        echo "Cambios a sincronizar (dry-run):"
        rsync -avzn $EXCLUDE_ARGS \
            -e "ssh -i $SSH_KEY" \
            "$LOCAL_KNOWLEDGE_DIR/" \
            "$REMOTE_USER@$REMOTE_HOST:$REMOTE_KNOWLEDGE_DIR/"

        echo ""
        read -p "Continuar con sync? [y/N] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelado."
            exit 0
        fi

        # Sync real
        rsync -avz $EXCLUDE_ARGS \
            -e "ssh -i $SSH_KEY" \
            "$LOCAL_KNOWLEDGE_DIR/" \
            "$REMOTE_USER@$REMOTE_HOST:$REMOTE_KNOWLEDGE_DIR/"
        ;;

    pull)
        echo "Obteniendo conocimiento del servidor remoto..."

        # Dry run primero para ver cambios
        echo ""
        echo "Cambios a sincronizar (dry-run):"
        rsync -avzn $EXCLUDE_ARGS \
            -e "ssh -i $SSH_KEY" \
            "$REMOTE_USER@$REMOTE_HOST:$REMOTE_KNOWLEDGE_DIR/" \
            "$LOCAL_KNOWLEDGE_DIR/"

        echo ""
        read -p "Continuar con sync? [y/N] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelado."
            exit 0
        fi

        # Sync real
        rsync -avz $EXCLUDE_ARGS \
            -e "ssh -i $SSH_KEY" \
            "$REMOTE_USER@$REMOTE_HOST:$REMOTE_KNOWLEDGE_DIR/" \
            "$LOCAL_KNOWLEDGE_DIR/"
        ;;

    *)
        echo "Uso: $0 [push|pull]"
        echo "  push - Envia cambios locales al remoto"
        echo "  pull - Trae cambios del remoto al local"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "Knowledge sync completado: $DATE"
echo "Local:  $LOCAL_KNOWLEDGE_DIR"
echo "Remoto: $REMOTE_USER@$REMOTE_HOST:$REMOTE_KNOWLEDGE_DIR"
echo "=========================================="
