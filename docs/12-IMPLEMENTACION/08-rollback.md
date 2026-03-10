# Estrategia de Rollback

**ID:** DOC-IMP-ROL-001
**Versión:** 1.0
**Fecha:** 2026-03-10
**Estado:** Procedimiento Operativo

---

## Resumen

Este documento define el procedimiento de rollback para OPENCLAW-system, incluyendo criterios de decisión, comandos específicos y pasos de verificación.

---

## 1. Criterios de Decisión de Rollback

### 1.1 Ejecutar Rollback Inmediato

| Condición | Severidad | Acción |
|-----------|-----------|--------|
| Sistema no responde | CRÍTICA | Rollback inmediato |
| Tasa de error > 50% | CRÍTICA | Rollback inmediato |
| Gateway caído > 5 min | CRÍTICA | Rollback inmediato |
| Pérdida de datos | CRÍTICA | Rollback + restaurar backup |
| Memoria > 95% uso | ALTA | Rollback en 15 min |
| Latencia > 5s | ALTA | Investigar, rollback si persiste |
| Funcionalidad clave rota | ALTA | Rollback en 30 min |

### 1.2 No Ejecutar Rollback

| Condición | Acción |
|-----------|--------|
| Error en 1 de 4 agentes | Reiniciar agente individual |
| Warning en logs | Investigar, monitorear |
| Feature opcional rota | Hotfix sin rollback |
| Performance degradado < 20% | Optimizar sin rollback |

---

## 2. Tipos de Rollback

### 2.1 Rollback de Código

Revertir a versión anterior del software.

```bash
# Identificar versión actual
cd ~/projects/openclaw
git log -1 --oneline

# Ver commits recientes
git log --oneline -10

# Rollback a commit específico
git checkout <commit-hash>

# Reconstruir
node scripts/tsdown-build.mjs
pm2 restart all

# Verificar
pm2 status
curl http://127.0.0.1:18789/health
```

### 2.2 Rollback de Configuración

Revertir cambios en archivos de configuración.

```bash
# Restaurar .env desde backup
cp ~/.openclaw/backups/.env.20260310 ~/.openclaw/config/.env
chmod 600 ~/.openclaw/config/.env

# Restaurar ecosystem.config.js
cp ~/projects/openclaw/backups/ecosystem.config.js.20260310 \
   ~/projects/openclaw/ecosystem.config.js

# Reiniciar con configuración anterior
pm2 restart all --update-env
```

### 2.3 Rollback de Base de Datos

Restaurar datos desde backup.

```bash
# Redis
sudo systemctl stop redis-server
cp /backup/redis/dump-20260310.rdb /var/lib/redis/dump-openclaw.rdb
sudo systemctl start redis-server

# SQLite/LanceDB
cp /backup/openclaw/data/memory-20260310.db ~/.openclaw/data/memory.db
```

---

## 3. Procedimiento de Rollback Completo

### 3.1 Pre-Rollback

```bash
#!/bin/bash
# scripts/pre-rollback.sh

echo "=== PRE-ROLLBACK CHECKS ==="

# 1. Documentar estado actual
echo "1. Documentando estado actual..."
mkdir -p ~/rollback-snapshots
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Capturar versión
git -C ~/projects/openclaw log -1 > ~/rollback-snapshots/version-$TIMESTAMP.txt

# Capturar estado PM2
pm2 status > ~/rollback-snapshots/pm2-status-$TIMESTAMP.txt
pm2 save

# Capturar logs
cp -r ~/.openclaw/logs ~/rollback-snapshots/logs-$TIMESTAMP

echo "Snapshot guardado en: ~/rollback-snapshots/$TIMESTAMP"
```

### 3.2 Ejecutar Rollback

```bash
#!/bin/bash
# scripts/rollback.sh

set -e

ROLLBACK_VERSION=${1:-"HEAD~1"}  # Por defecto, versión anterior

echo "=== ROLLBACK OPENCLAW-SYSTEM ==="
echo "Target: $ROLLBACK_VERSION"
echo ""

# Confirmar
read -p "¿Continuar con rollback? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Rollback cancelado"
    exit 1
fi

# 1. Detener servicios
echo "1. Deteniendo servicios..."
pm2 stop all

# 2. Backup de estado actual
echo "2. Creando backup de seguridad..."
BACKUP_DIR="~/backups/pre-rollback-$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR
cp -r ~/.openclaw/config $BACKUP_DIR/
cp ~/projects/openclaw/ecosystem.config.js $BACKUP_DIR/

# 3. Rollback de código
echo "3. Revirtiendo código..."
cd ~/projects/openclaw
git fetch origin
git checkout $ROLLBACK_VERSION

# 4. Reinstalar dependencias
echo "4. Reinstalando dependencias..."
pnpm install --frozen-lockfile

# 5. Reconstruir
echo "5. Reconstruyendo..."
node scripts/tsdown-build.mjs

# 6. Iniciar servicios
echo "6. Iniciando servicios..."
pm2 start all

# 7. Esperar estabilización
echo "7. Esperando estabilización..."
sleep 10

# 8. Verificar
echo "8. Verificando..."
pm2 status

# Health check
if curl -sf http://127.0.0.1:18789/health > /dev/null; then
    echo "✅ Gateway OK"
else
    echo "❌ Gateway NO responde"
    exit 1
fi

echo ""
echo "=== ROLLBACK COMPLETADO ==="
echo "Backup guardado en: $BACKUP_DIR"
echo "Versión actual: $(git log -1 --oneline)"
```

### 3.3 Post-Rollback

```bash
#!/bin/bash
# scripts/post-rollback.sh

echo "=== POST-ROLLBACK VERIFICATION ==="

# 1. Verificar servicios
echo "1. Estado de servicios:"
pm2 status

# 2. Verificar conectividad
echo ""
echo "2. Health checks:"
curl -sf http://127.0.0.1:18789/health && echo " Gateway OK"
curl -sf http://127.0.0.1:11434/api/version && echo " Ollama OK"

# 3. Verificar logs sin errores críticos
echo ""
echo "3. Errores recientes:"
pm2 logs --lines 20 --err | grep -c "ERROR" | xargs -I{} echo "Errores encontrados: {}"

# 4. Métricas básicas
echo ""
echo "4. Métricas:"
echo "Memoria: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
echo "Disco: $(df -h ~ | tail -1 | awk '{print $3 "/" $2}')"

# 5. Test funcional básico
echo ""
echo "5. Test funcional:"
RESPONSE=$(curl -s -X POST http://127.0.0.1:11434/api/chat \
  -d '{"model":"llama3.2:3b","messages":[{"role":"user","content":"test"}],"stream":false}' \
  | jq -r '.message.content' 2>/dev/null)

if [ -n "$RESPONSE" ]; then
    echo "✅ LLM responde correctamente"
else
    echo "⚠️ LLM no responde - verificar Ollama"
fi

echo ""
echo "=== VERIFICACIÓN COMPLETADA ==="
```

---

## 4. Rollback por Componente

### 4.1 Solo Gateway

```bash
# Detener solo gateway
pm2 stop sis-gateway

# Restaurar versión anterior
cd ~/projects/openclaw
git checkout HEAD~1 -- dist/gateway/
pm2 restart sis-gateway

# Verificar
curl http://127.0.0.1:18789/health
```

### 4.2 Solo Director

```bash
pm2 stop sis-director
git checkout HEAD~1 -- dist/agents/director/
pm2 restart sis-director
```

### 4.3 Solo Ejecutor

```bash
pm2 stop sis-ejecutor
git checkout HEAD~1 -- dist/agents/ejecutor/
pm2 restart sis-ejecutor
```

### 4.4 Solo Archivador

```bash
pm2 stop sis-archivador
git checkout HEAD~1 -- dist/agents/archivador/
pm2 restart sis-archivador
```

---

## 5. Rollback de Emergencia

### 5.1 Script de Emergencia

```bash
#!/bin/bash
# scripts/emergency-rollback.sh
# Ejecutar cuando el sistema está completamente caído

set -e

echo "=== ROLLBACK DE EMERGENCIA ==="

# 1. Matar todos los procesos Node
echo "1. Terminando procesos..."
pm2 kill 2>/dev/null || true
pkill -f "openclaw" || true

# 2. Restaurar última versión estable conocida
echo "2. Restaurando versión estable..."
cd ~/projects/openclaw
git fetch origin
git checkout origin/stable  # Asumiendo rama stable
git reset --hard origin/stable

# 3. Limpiar y reconstruir
echo "3. Limpiando y reconstruyendo..."
rm -rf node_modules dist
pnpm install --frozen-lockfile
node scripts/tsdown-build.mjs

# 4. Iniciar
echo "4. Iniciando servicios..."
pm2 start ecosystem.config.js
pm2 save

# 5. Verificar
echo "5. Verificando..."
sleep 15
pm2 status

echo "=== ROLLBACK DE EMERGENCIA COMPLETADO ==="
```

### 5.2 Restauración desde Backup Completo

```bash
#!/bin/bash
# scripts/restore-from-backup.sh

BACKUP_DIR=$1

if [ -z "$BACKUP_DIR" ]; then
    echo "Uso: $0 <directorio-backup>"
    echo "Backups disponibles:"
    ls -la ~/backups/
    exit 1
fi

echo "=== RESTAURANDO DESDE BACKUP: $BACKUP_DIR ==="

# Detener todo
pm2 stop all

# Restaurar código
rm -rf ~/projects/openclaw
cp -r $BACKUP_DIR/openclaw ~/projects/

# Restaurar configuración
cp -r $BACKUP_DIR/.openclaw ~/.openclaw

# Restaurar datos
cp -r $BACKUP_DIR/data ~/.openclaw/

# Restaurar Redis
sudo systemctl stop redis-server
cp $BACKUP_DIR/redis/dump-*.rdb /var/lib/redis/dump-openclaw.rdb
sudo systemctl start redis-server

# Iniciar
cd ~/projects/openclaw
pm2 start ecosystem.config.js
pm2 save

echo "=== RESTAURACIÓN COMPLETADA ==="
```

---

## 6. Matriz de Decisión

```
┌─────────────────────────────────────────────────────────────┐
│                    DECISIÓN DE ROLLBACK                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ¿Sistema accesible?                                        │
│         │                                                   │
│    ┌────┴────┐                                              │
│    │         │                                              │
│   SÍ        NO ──► Rollback de Emergencia                   │
│    │                                                         │
│    ▼                                                         │
│  ¿Error en 1 componente o todos?                            │
│         │                                                   │
│    ┌────┴────┐                                              │
│    │         │                                              │
│   1         TODOS                                           │
│    │         │                                              │
│    ▼         ▼                                              │
│ Rollback   Rollback                                         │
│ Individual Completo                                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. Checklist de Rollback

```markdown
## Pre-Rollback
- [ ] Documentado estado actual
- [ ] Backup de configuración creado
- [ ] Confirmación de equipo obtenida

## Durante Rollback
- [ ] Servicios detenidos correctamente
- [ ] Código revertido
- [ ] Dependencias reinstaladas
- [ ] Build completado sin errores
- [ ] Servicios reiniciados

## Post-Rollback
- [ ] pm2 status muestra todos online
- [ ] Health check Gateway OK
- [ ] Health check Ollama OK
- [ ] Logs sin errores críticos
- [ ] Test funcional básico OK
- [ ] Equipo notificado

## Documentación
- [ ] Incidente documentado
- [ ] Causa raíz identificada
- [ ] Acciones correctivas asignadas
```

---

## 8. Contactos y Escalamiento

| Nivel | Rol | Contacto | Tiempo Respuesta |
|-------|-----|----------|------------------|
| 1 | On-call | @oncall | 15 min |
| 2 | Tech Lead | @techlead | 30 min |
| 3 | CTO | @cto | 1 hora |

---

**Documento:** Estrategia de Rollback
**ID:** DOC-IMP-ROL-001
**Versión:** 1.0
**Fecha:** 2026-03-10
