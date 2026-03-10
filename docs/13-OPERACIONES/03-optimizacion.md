# Optimización de Rendimiento

**ID:** DOC-OPE-OPT-001
**Última actualización:** 2026-03-09
**Versión:** 1.0
**Categoría:** Operaciones

---

## 📋 Introducción

Este documento describe las estrategias y técnicas de optimización de rendimiento para el OPENCLAW-system v1.0. La optimización es un proceso continuo que requiere monitoreo, análisis y ajustes iterativos.

### Objetivos de Optimización

- **Latencia:** Respuesta p95 < 5 segundos, p99 < 10 segundos
- **Throughput:** Soportar 100+ requests concurrentes en producción
- **Eficiencia:** Uso óptimo de CPU, memoria y disco
- **Escalabilidad:** Sistema preparado para crecimiento lineal

---

## 🖥️ Optimización de Recursos de Sistema

### Optimización de CPU

#### Afinidad de Procesos

PM2 permite asignar afinidad de CPU a cada proceso:

```javascript
// ecosystem.config.js
module.exports = {
  apps: [
    {
      name: 'sis-director',
      script: './bin/manager.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_OPTIONS: '--max-old-space-size=2048'
      }
    },
    {
      name: 'sis-ejecutor',
      script: './bin/ejecutor.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_OPTIONS: '--max-old-space-size=4096'
      }
    },
    {
      name: 'sis-archivador',
      script: './bin/archivador.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_OPTIONS: '--max-old-space-size=2048'
      }
    }
  ]
}
```

#### Prioridades de Proceso

```bash
# Prioridad alta para el Director (latencia crítica)
sudo renice -5 $(pgrep -f "sis-director")

# Prioridad normal para el Ejecutor (default)

# Prioridad baja para el Archivador (tarea de fondo)
sudo renice +5 $(pgrep -f "sis-archivador")
```

### Optimización de Memoria RAM

#### Límites de Memoria por Engranaje

```javascript
// ecosystem.config.js
module.exports = {
  apps: [
    {
      name: 'sis-director',
      max_memory_restart: '2G',
      env: {
        NODE_OPTIONS: '--max-old-space-size=2048'
      }
    },
    {
      name: 'sis-ejecutor',
      max_memory_restart: '4G',
      env: {
        NODE_OPTIONS: '--max-old-space-size=4096'
      }
    },
    {
      name: 'sis-archivador',
      max_memory_restart: '3G',
      env: {
        NODE_OPTIONS: '--max-old-space-size=3072'
      }
    }
  ]
}
```

### Optimización de Red

#### Optimización de WebSocket

```javascript
// Configuración del Gateway
const gatewayConfig = {
  port: 18789,
  pingInterval: 30000,
  pingTimeout: 5000,
  maxHttpBufferSize: 1e6,
  transports: ['websocket'],
  perMessageDeflate: {
    threshold: 1024,
    zlibDeflateOptions: {
      level: 3,
      concurrency: 10
    }
  }
};
```

---

## 🤖 Optimización de Modelos de IA

### Caché de Respuestas

Implementar caché LRU para respuestas recurrentes usando Redis:

```typescript
import { CacheManager } from 'cache-manager';
import { store } from 'cache-manager-ioredis';

const cache = await CacheManager.create(store, {
  host: 'localhost',
  port: 6379,
  ttl: 3600
});

const llmCache = {
  key: (prompt: string, model: string) => {
    return hash(`${model}:${prompt}`);
  },
  get: async (prompt: string, model: string) => {
    const key = llmCache.key(prompt, model);
    return await cache.get(key);
  },
  set: async (prompt: string, model: string, response: string) => {
    const key = llmCache.key(prompt, model);
    await cache.set(key, response, { ttl: 3600 });
  }
};
```

### Selección Inteligente de Modelo

```typescript
interface ModelCapabilities {
  name: string;
  reasoning: number;
  speed: number;
  cost: number;
  maxTokens: number;
}

const models: ModelCapabilities[] = [
  { name: 'gpt-4', reasoning: 10, speed: 3, cost: 30, maxTokens: 8192 },
  { name: 'gpt-3.5-turbo', reasoning: 7, speed: 9, cost: 2, maxTokens: 4096 },
  { name: 'claude-3-5-sonnet', reasoning: 10, speed: 4, cost: 15, maxTokens: 200000 },
  { name: 'gemini-1.5-flash', reasoning: 6, speed: 10, cost: 0.075, maxTokens: 1000000 }
];

function selectModel(task: {
  complexity: 'low' | 'medium' | 'high';
  priority: 'speed' | 'quality' | 'cost';
}): ModelCapabilities {
  let candidates = models;

  if (task.complexity === 'high') {
    candidates = candidates.filter(m => m.reasoning >= 8);
  }

  if (task.priority === 'speed') {
    candidates.sort((a, b) => a.speed - b.speed);
  } else if (task.priority === 'quality') {
    candidates.sort((a, b) => b.reasoning - a.reasoning);
  } else if (task.priority === 'cost') {
    candidates.sort((a, b) => a.cost - b.cost);
  }

  return candidates[0];
}
```

---

## 🧠 Optimización de RAG

### Indexación Incremental

```typescript
async function incrementalIndex(vaultPath: string) {
  const lastIndex = await readLastIndex();
  const changedFiles = await scanChangedFiles(vaultPath, lastIndex.timestamp);
  const documents = await Promise.all(changedFiles.map(file => readFile(file)));
  const embeddings = await batchEmbed(documents.map(d => d.content));
  await updateIndex(embeddings);
  await saveLastIndex({ timestamp: Date.now() });
}
```

### Búsqueda Híbrida Eficiente

```typescript
async function hybridSearch(query: string, topK: number = 10) {
  const keywordResults = await keywordSearch(query, topK * 2);
  const semanticResults = await semanticSearch(query, topK * 2);
  const rrf = reciprocalRankFusion([
    { results: keywordResults, weight: 0.5 },
    { results: semanticResults, weight: 0.5 }
  ]);
  const mmrResults = maximalMarginalRelevance(rrf, topK, 0.5);
  return mmrResults;
}
```

---

## 🔄 Optimización de Comunicación R-P-V

### Pipeline Paralelo

```typescript
async function optimizedRPV(request: Request) {
  const results = await Promise.allSettled([
    manager.plan(request),
    archivist.searchContext(request),
    gateway.validate(request)
  ]);

  const [plan, context, validation] = results.map(r =>
    r.status === 'fulfilled' ? r.value : null
  );

  if (!validation.valid) {
    return { error: 'Invalid request', details: validation.errors };
  }

  const execution = await worker.execute(plan, context);
  archivist.storeLesson(request, plan, execution).catch(err => {
    console.error('Failed to store lesson:', err);
  });

  return execution;
}
```

---

## 📊 Métricas de Rendimiento

### KPIs Clave

| Métrica | Objetivo | Alerta |
|---------|-----------|--------|
| Latencia p95 | < 5s | > 5s |
| Latencia p99 | < 10s | > 10s |
| Throughput | > 50 req/s | < 10 req/s |
| CPU Usage | < 80% | > 90% |
| Memory Usage | < 85% | > 95% |

### Script de Monitoreo

```bash
#!/bin/bash
# monitor-resources.sh

CPU_THRESHOLD=90
MEM_THRESHOLD=95

cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
mem_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}')

if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
  echo "⚠️ CPU alta: ${cpu_usage}%"
fi

if (( $(echo "$mem_usage > $MEM_THRESHOLD" | bc -l) )); then
  echo "⚠️ Memoria alta: ${mem_usage}%"
fi
```

---

## 🔧 Herramientas de Periling

### Node.js Profiler

```bash
# Generar perfil de CPU
pm2 profile:profiling --action stop
pm2 generate-profile

# Generar perfil de memoria
pm2 profile:profiling [pid] --action start --memory
pm2 profile:profiling [pid] --action stop
pm2 generate-profile
```

### PM2 Monitoring

```bash
# Monitoreo en tiempo real
pm2 monit

# Información detallada
pm2 show [app-name]

# Logs en tiempo real
pm2 logs [app-name]
```

---

## 📈 Optimización Continua

### Ciclo de Optimización

1. **Monitorear** - Recolectar métricas continuamente
2. **Analizar** - Identificar cuellos de botella
3. **Optimizar** - Implementar mejoras
4. **Validar** - Verificar impacto
5. **Iterar** - Repetir ciclo

### Checklist de Optimización

- [ ] Ajustar afinidad de CPU
- [ ] Configurar límites de memoria
- [ ] Implementar caché de respuestas
- [ ] Habilitar streaming para respuestas largas
- [ ] Optimizar consultas RAG
- [ ] Configurar compresión de WebSocket
- [ ] Ajustar parámetros del kernel
- [ ] Implementar monitoreo de métricas
- [ ] Configurar alertas automáticas
- [ ] Documentar todos los cambios

---

**Última revisión:** 2026-03-09
**Próxima revisión:** 2026-06-09 (trimestral)
