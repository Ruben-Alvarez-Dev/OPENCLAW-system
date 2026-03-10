# Runbook de Respuesta a Incidentes

**ID:** DOC-OPE-INC-001
**Versión:** 1.0
**Fecha:** 2026-03-10
**Estado:** Procedimiento Operativo Crítico

---

## 1. Clasificación de Incidentes

### 1.1 Niveles de Severidad

| Nivel | Nombre | Criterio | Tiempo Respuesta |
|-------|--------|----------|------------------|
| **SEV-1** | Crítico | Sistema completamente caído | 15 minutos |
| **SEV-2** | Alto | Funcionalidad principal afectada | 30 minutos |
| **SEV-3** | Medio | Funcionalidad secundaria afectada | 2 horas |
| **SEV-4** | Bajo | Problema cosmético o menor | 1 día |

### 1.2 Ejemplos por Severidad

| SEV-1 | SEV-2 | SEV-3 | SEV-4 |
|-------|-------|-------|-------|
| Gateway no responde | 1 agente caído | Memoria alta | Warning en logs |
| Todos los procesos down | LLM no disponible | Latencia alta | UI menor |
| Pérdida de datos | Error en 50% requests | 1 canal offline | Docs desactualizadas |
| Seguridad comprometida | Backup fallido | Feature opcional roto | Performance menor |

---

## 2. Flujo de Respuesta

```
┌─────────────────────────────────────────────────────────────────┐
│                    DETECCIÓN                                    │
│  (Alerta, Usuario, Monitoreo)                                  │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    TRIAGE (5 min)                               │
│  • Clasificar severidad                                        │
│  • Asignar responsable                                         │
│  • Notificar stakeholders                                      │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CONTENCIÓN (15 min)                          │
│  • Detener propagación                                         │
│  • Preservar evidencia                                         │
│  • Comunicar estado                                            │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    RESOLUCIÓN (Variable)                        │
│  • Identificar causa raíz                                      │
│  • Aplicar fix                                                 │
│  • Verificar solución                                          │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    RECUPERACIÓN (30 min)                        │
│  • Restaurar servicios                                         │
│  • Verificar integridad                                        │
│  • Monitorear estabilidad                                      │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    POST-MORTEM (24-72h)                         │
│  • Documentar incidente                                        │
│  • Análisis de causa raíz                                      │
│  • Acciones correctivas                                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Procedimientos por Incidente

### 3.1 SEV-1: Sistema Completamente Caído

```bash
#!/bin/bash
# runbooks/sev1-system-down.sh

echo "=== SEV-1: SISTEMA CAÍDO ==="
echo "Inicio: $(date)"

# 1. Verificar estado
echo "1. Verificando estado..."
pm2 status
ss -tlnp | grep -E "18789|11434"

# 2. Intentar recuperación rápida
echo "2. Intentando recuperación rápida..."
pm2 restart all
sleep 10

# 3. Verificar
pm2 status
curl -sf http://127.0.0.1:18789/health

# 4. Si falla, rollback de emergencia
if [ $? -ne 0 ]; then
    echo "3. Ejecutando rollback de emergencia..."
    ~/projects/openclaw/scripts/emergency-rollback.sh
fi

# 5. Notificar
echo "4. Sistema restaurado: $(date)"
```

### 3.2 SEV-1: Gateway No Responde

```bash
#!/bin/bash
# runbooks/sev1-gateway-down.sh

echo "=== SEV-1: GATEWAY DOWN ==="

# 1. Verificar proceso
if ! pm2 status | grep -q "sis-gateway.*online"; then
    echo "Gateway no está online. Reiniciando..."
    pm2 restart sis-gateway
fi

# 2. Verificar puerto
if ! ss -tlnp | grep -q 18789; then
    echo "Puerto 18789 no escuchando. Verificando errores..."
    pm2 logs sis-gateway --lines 50 --err

    # Matar proceso zombie si existe
    sudo lsof -ti:18789 | xargs -r sudo kill -9

    # Reiniciar
    pm2 restart sis-gateway
fi

# 3. Verificar health
for i in {1..5}; do
    if curl -sf http://127.0.0.1:18789/health > /dev/null; then
        echo "✅ Gateway restaurado"
        exit 0
    fi
    echo "Intento $i fallido, esperando..."
    sleep 5
done

echo "❌ Gateway no responde. Escalar."
exit 1
```

### 3.3 SEV-2: LLM No Disponible

```bash
#!/bin/bash
# runbooks/sev2-llm-unavailable.sh

echo "=== SEV-2: LLM NO DISPONIBLE ==="

# 1. Verificar Ollama
if ! curl -sf http://127.0.0.1:11434/api/version > /dev/null; then
    echo "Ollama no responde. Reiniciando..."
    sudo systemctl restart ollama
    sleep 10
fi

# 2. Verificar modelo
if ! ollama list | grep -q "llama3.2:3b"; then
    echo "Modelo no disponible. Descargando..."
    ollama pull llama3.2:3b
fi

# 3. Test de generación
RESPONSE=$(curl -s -X POST http://127.0.0.1:11434/api/chat \
    -d '{"model":"llama3.2:3b","messages":[{"role":"user","content":"test"}],"stream":false}')

if echo "$RESPONSE" | jq -e '.message' > /dev/null 2>&1; then
    echo "✅ LLM operativo"
else
    echo "❌ LLM sigue fallando. Verificar GPU/memoria."
    echo "Respuesta: $RESPONSE"
fi
```

### 3.4 SEV-2: Agente Caído

```bash
#!/bin/bash
# runbooks/sev2-agent-down.sh

AGENT=$1

if [ -z "$AGENT" ]; then
    echo "Uso: $0 <director|ejecutor|archivador>"
    exit 1
fi

echo "=== SEV-2: AGENTE $AGENT CAÍDO ==="

# 1. Verificar estado
pm2 status | grep sis-$AGENT

# 2. Ver logs de error
echo "Últimos errores:"
pm2 logs sis-$AGENT --lines 30 --err

# 3. Reiniciar
echo "Reiniciando agente..."
pm2 restart sis-$AGENT

# 4. Verificar
sleep 10
pm2 status | grep sis-$AGENT

# 5. Test de conectividad con Gateway
pm2 logs sis-$AGENT --lines 10 | grep -q "connected" && \
    echo "✅ Agente conectado al Gateway" || \
    echo "⚠️ Agente no muestra conexión"
```

### 3.5 SEV-3: Memoria Alta

```bash
#!/bin/bash
# runbooks/sev3-memory-high.sh

THRESHOLD=90

echo "=== SEV-3: MEMORIA ALTA ==="

# 1. Ver uso actual
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
echo "Uso de memoria: ${MEMORY_USAGE}%"

if [ "$MEMORY_USAGE" -gt "$THRESHOLD" ]; then
    echo "Memoria sobre umbral ${THRESHOLD}%"

    # 2. Identificar procesos
    echo "Top consumidores:"
    ps aux --sort=-%mem | head -10

    # 3. Limpiar caches de Node.js
    echo "Reiniciando agentes para liberar memoria..."
    pm2 restart all

    # 4. Limpiar logs antiguos
    find ~/.openclaw/logs -name "*.log" -mtime +7 -delete

    # 5. Verificar de nuevo
    NEW_MEMORY=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
    echo "Nuevo uso de memoria: ${NEW_MEMORY}%"
fi
```

---

## 4. Contactos y Escalamiento

### 4.1 Matriz de Escalamiento

| Severidad | 15 min | 30 min | 1 hora | 2 horas |
|-----------|--------|--------|--------|---------|
| SEV-1 | On-call | Tech Lead | CTO | CEO |
| SEV-2 | On-call | Tech Lead | CTO | - |
| SEV-3 | On-call | Tech Lead | - | - |
| SEV-4 | On-call | - | - | - |

### 4.2 Canales de Comunicación

| Canal | Uso | Severidad |
|-------|-----|-----------|
| Slack #incidents | Coordinación | SEV-2, SEV-3, SEV-4 |
| Teléfono/SMS | Urgente | SEV-1 |
| Email | Notificación | Todos |

### 4.3 Plantilla de Comunicación

```
🚨 INCIDENTE [SEV-X]

Estado: [INVESTIGANDO|CONTENIDO|RESUELTO]
Sistema: OPENCLAW-system
Impacto: [Describir qué está afectado]
Inicio: [Timestamp]
Responsable: [Nombre]

Acciones en curso:
- [ ] Acción 1
- [ ] Acción 2

Próxima actualización: [+15 min]
```

---

## 5. Post-Mortem Template

```markdown
# Post-Mortem: [Título del Incidente]

**Fecha:** YYYY-MM-DD
**Severidad:** SEV-X
**Duración:** X horas Y minutos
**Responsable:** Nombre

## Resumen
[1-2 frases describiendo el incidente]

## Impacto
- Usuarios afectados: X
- Duración del servicio caído: X min
- Datos afectados: [Ninguno/Describir]

## Línea de Tiempo
| Hora | Evento |
|------|--------|
| HH:MM | Detección |
| HH:MM | Triage |
| HH:MM | Contención |
| HH:MM | Resolución |
| HH:MM | Recuperación completa |

## Causa Raíz
[Descripción técnica de la causa raíz]

## Factores Contribuyentes
1. Factor 1
2. Factor 2

## Acciones Correctivas
| Acción | Propietario | Fecha Límite |
|--------|-------------|--------------|
| Acción 1 | @persona | YYYY-MM-DD |
| Acción 2 | @persona | YYYY-MM-DD |

## Lecciones Aprendidas
- Qué funcionó bien
- Qué mejorar

## Anexos
- Logs relevantes
- Métricas
- Screenshots
```

---

## 6. Herramientas de Diagnóstico

```bash
#!/bin/bash
# runbooks/diagnostic.sh

echo "=== DIAGNÓSTICO COMPLETO ==="
echo "Timestamp: $(date)"
echo ""

echo "=== SISTEMA ==="
uptime
free -h
df -h
echo ""

echo "=== PROCESOS ==="
pm2 status
echo ""

echo "=== PUERTOS ==="
ss -tlnp | grep -E "18789|11434|6379"
echo ""

echo "=== LOGS RECIENTES ==="
pm2 logs --lines 20 --nostream
echo ""

echo "=== REDIS ==="
redis-cli INFO | grep -E "used_memory|connected_clients"
echo ""

echo "=== OLLAMA ==="
ollama ps
ollama list
echo ""

echo "=== FIREWALL ==="
sudo ufw status
```

---

## 7. Checklist de Recuperación

```markdown
## Post-Incidente
- [ ] Todos los servicios online
- [ ] Health checks pasando
- [ ] Logs sin errores críticos
- [ ] Métricas normalizadas
- [ ] Usuarios notificados
- [ ] Post-mortem programado
```

---

**Documento:** Runbook de Respuesta a Incidentes
**ID:** DOC-OPE-INC-001
**Versión:** 1.0
**Fecha:** 2026-03-10
