# Depuración y Troubleshooting

**Versión:** OPENCLAW-system v2.1  
**Fecha:** 2026-03-09  
**Estado:** Documentación Técnica

---

## 1. Herramientas de Debugging

### 1.1 PM2 Logs (Tiempo Real)

```bash
# Logs de todos los agentes
pm2 logs

# Logs de agente específico
pm2 logs sis-director
pm2 logs sis-ejecutor
pm2 logs sis-archivador

# Últimas N líneas
pm2 logs sis-director --lines 200

# Filtrar por patrones
pm2 logs sis-director | grep "ERROR"
pm2 logs | grep -E "(WARN|ERROR)"

# Flush de logs
pm2 flush
```

### 1.2 PM2 Attach

```bash
# Ver procesos
pm2 list

# Información detallada
pm2 show sis-director

# Modo monitoring
pm2 monit

# Attach a proceso
pm2 attach sis-director
```

### 1.3 Node.js Inspector

```bash
# Iniciar en modo debug
pm2 start ecosystem.config.js --node-args="--inspect=9229"

# Conectar desde Chrome
# chrome://inspect

# Conectar desde VSCode
# Usar "Attach to PM2 Process"
```

### 1.4 VSCode Debugger

**Configuración `.vscode/launch.json`:**

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Director",
      "runtimeExecutable": "pnpm",
      "runtimeArgs": ["start:dev:director"],
      "console": "integratedTerminal"
    },
    {
      "type": "node",
      "request": "attach",
      "name": "Attach PM2 Director",
      "port": 9229,
      "restart": true
    },
    {
      "type": "node",
      "request": "attach",
      "name": "Attach PM2 Ejecutor",
      "port": 9230,
      "restart": true
    }
  ]
}
```

---

## 2. Debugging del Director

### 2.1 Seguimiento de Decisiones

```typescript
// Habilitar debug logging
logger.setLevel('debug');

// Trace de decisiones
director.on('decision', (decision) => {
  logger.debug('Decision made', {
    intent: decision.intent,
    strategy: decision.strategy,
    confidence: decision.confidence
  });
});
```

### 2.2 Análisis de Delegaciones

```bash
# Ver delegaciones en logs
pm2 logs sis-director | grep "delegat"

# Debug de delegacion
DEBUG=director:delegation pm2 restart sis-director
```

### 2.3 Validación de Respuestas

```typescript
async function debugValidation(result: EjecutorResult, criteria: ValidationCriteria) {
  console.log('=== VALIDATION DEBUG ===');
  console.log('Ejecutor result:', result);
  console.log('Validation criteria:', criteria);
  
  if (criteria.intentMatch < 0.8) {
    console.warn('LOW INTENT MATCH:', criteria.intentMatch);
  }
  
  if (!criteria.safetyCompliance) {
    console.error('SAFETY VIOLATION DETECTED');
  }
}
```

---

## 3. Debugging del Ejecutor

### 3.1 Seguimiento de Ejecución

```typescript
ejecutor.on('execution:start', (task) => {
  logger.debug('Execution started', { taskId: task.id });
});

ejecutor.on('execution:step', (step) => {
  logger.debug('Execution step', { step: step.name, duration: step.duration });
});

ejecutor.on('execution:complete', (result) => {
  logger.debug('Execution completed', { success: result.success });
});
```

### 3.2 Debugging de Tools

```bash
# Ver ejecucion de tools
DEBUG=ejecutor:tools pm2 logs sis-ejecutor

# Tool especifico
DEBUG=ejecutor:tools:browser pm2 logs sis-ejecutor
```

### 3.3 Análisis de Errores de Sandbox

```typescript
async function debugSandboxError(error: SandboxError) {
  console.log('=== SANDBOX ERROR DEBUG ===');
  console.log('Error type:', error.type);
  console.log('Container ID:', error.containerId);
  console.log('Exit code:', error.exitCode);
  console.log('Stdout:', error.stdout);
  console.log('Stderr:', error.stderr);
}
```

---

## 4. Debugging del Archivador

### 4.1 Verificación de Almacenamiento

```typescript
async function debugStorage(knowledge: Knowledge) {
  console.log('=== STORAGE DEBUG ===');
  
  const stored = await vault.get(knowledge.id);
  console.log('Stored successfully:', !!stored);
  console.log('Vector ID:', stored?.vectorId);
}
```

### 4.2 Debugging de RAG

```typescript
async function debugRAG(query: string) {
  console.log('=== RAG DEBUG ===');
  console.log('Query:', query);
  
  // Embedding
  const embedding = await embeddings.embed(query);
  console.log('Embedding dimensions:', embedding.length);
  
  // Búsqueda vectorial
  const results = await vectorStore.search(embedding, { topK: 10 });
  console.log('Results:', results.length);
  
  return results;
}
```

---

## 5. Troubleshooting Común

### 5.1 Agente No Responde

**Diagnóstico:**

```bash
pm2 list
pm2 show sis-director
pm2 logs sis-director --lines 50
```

**Soluciones:**

```bash
# Reiniciar agente
pm2 restart sis-director

# Si no responde
pm2 delete sis-director
pm2 start ecosystem.config.js --only sis-director

# Verificar configuracion
cat ~/.openclaw/agents/director/openclaw.json
```

### 5.2 Gateway Desconectado

**Diagnóstico:**

```bash
pm2 list | grep gateway
lsof -i :18789
curl http://localhost:18789/health
```

**Soluciones:**

```bash
pm2 restart sis-gateway
netstat -tlnp | grep 18789
pm2 restart all
```

### 5.3 Error de Comunicación R-P-V

**Diagnóstico:**

```bash
pm2 logs | grep -E "(ECONNREFUSED|ETIMEDOUT)"
pm2 logs | grep "queue"
```

**Soluciones:**

```bash
pm2 restart sis-ejecutor sis-director
pm2 show sis-ejecutor | grep script
```

### 5.4 Error de Proveedor de IA

**Diagnóstico:**

```bash
env | grep API_KEY
curl -H "Authorization: Bearer $OPENAI_API_KEY" \
  https://api.openai.com/v1/models
```

**Soluciones:**

```bash
export OPENAI_API_KEY="sk-..."
pm2 restart all --update-env
```

### 5.5 Agotamiento de Memoria

**Diagnóstico:**

```bash
pm2 monit
node --inspect index.js
# Chrome DevTools → Memory → Heap snapshot
```

**Soluciones:**

```bash
pm2 start ecosystem.config.js --node-args="--max-old-space-size=4096"
pm2 start ecosystem.config.js --cron-restart="0 3 * * *"
```

### 5.6 CPU al 100%

**Diagnóstico:**

```bash
top -p $(pgrep -f "node.*openclaw")
node --prof index.js
node --prof-process isolate-*.log > profile.txt
```

**Soluciones:**

```bash
pm2 start ecosystem.config.js --max-memory-restart 500M
```

---

## 6. Herramientas de Diagnóstico

### 6.1 Comandos Útiles

```bash
# Estado completo
pm2 list && pm2 logs --lines 20

# Información detallada
pm2 show sis-director
pm2 describe sis-ejecutor

# Métricas en tiempo real
pm2 monit

# Logs del sistema (Linux)
journalctl -u openclaw -f

# Logs del sistema (macOS)
log stream --predicate 'process == "node"' --level debug
```

### 6.2 Health Check Script

```bash
#!/bin/bash
echo "=== OPENCLAW-system Health Check ==="

AGENTS=("sis-director" "sis-ejecutor" "sis-archivador")

for agent in "${AGENTS[@]}"; do
  STATUS=$(pm2 jlist | jq -r ".[] | select(.name==\"$agent\") | .pm2_env.status")
  if [ "$STATUS" == "online" ]; then
    echo "✅ $agent: online"
  else
    echo "❌ $agent: $STATUS"
  fi
done

if curl -s http://localhost:18789/health > /dev/null; then
  echo "✅ Gateway: healthy"
else
  echo "❌ Gateway: unhealthy"
fi
```

---

## 7. Profiling de Rendimiento

### 7.1 Node.js Profiler

```bash
node --prof index.js
node --prof-process isolate-*.log > profile.txt
```

### 7.2 Flamegraphs

```bash
npm install -g 0x
0x -o flamegraph.html index.js
open flamegraph.html
```

### 7.3 Memory Profiling

```bash
# Generar heap snapshot
kill -USR2 <pid>

# O programáticamente
const heapdump = require('heapdump');
heapdump.writeSnapshot('/tmp/heapdump-' + Date.now() + '.heapsnapshot');
```

---

## 8. Escenarios de Emergencia

### 8.1 Crash Total

```bash
pm2 list
pm2 restart all

# Si falla
pm2 delete all
pm2 start ecosystem.config.js

# Verificar errores
pm2 logs --err --lines 100
```

### 8.2 Bloqueo de Agentes

```bash
pm2 kill
ps aux | grep node
pkill -f "node.*openclaw"
pm2 start ecosystem.config.js
```

### 8.3 Corrupción de Datos

```bash
pm2 stop all
cp -r ~/.openclaw ~/.openclaw.corrupted
cp -r ~/.openclaw/backup/latest/* ~/.openclaw/
sqlite3 ~/.openclaw/vault.db "PRAGMA integrity_check;"
pm2 start all
```

---

## 9. Checklist de Troubleshooting

```markdown
## Diagnóstico Inicial
- [ ] `pm2 list` - ¿Todos los agentes online?
- [ ] `pm2 logs --lines 50` - ¿Hay errores recientes?
- [ ] `curl localhost:18789/health` - ¿Gateway responde?
- [ ] `free -h` - ¿Memoria disponible?
- [ ] `df -h` - ¿Espacio en disco?

## Si Agente No Responde
- [ ] `pm2 restart <agente>`
- [ ] `pm2 logs <agente> --lines 100`
- [ ] `pm2 show <agente>`
- [ ] Verificar configuración en ~/.openclaw/

## Si Gateway Falla
- [ ] Verificar puerto 18789 libre
- [ ] `pm2 restart sis-gateway`
- [ ] Verificar API keys en entorno

## Si Hay Memory Issues
- [ ] `pm2 monit` para ver uso
- [ ] Aumentar --max-old-space-size
- [ ] Generar heap snapshot
- [ ] Reiniciar agente problemático

## Escalado
- [ ] Guardar logs relevantes
- [ ] Documentar error exacto
- [ ] Crear issue con información
- [ ] Contactar equipo de soporte
```

---

## 10. Referencias

- [Guía de Desarrollo](./00-guia-desarrollo.md)
- [Testing y QA](./01-testing.md)
- [Ciclo de Vida](./02-ciclo-vida.md)
- [PM2 Docs](https://pm2.keymetrics.io/docs)
- [Node.js Debugging](https://nodejs.org/en/docs/guides/debugging-getting-started/)

---

**Última actualización:** 2026-03-09  
**Mantenido por:** Equipo de Desarrollo OPENCLAW-system
