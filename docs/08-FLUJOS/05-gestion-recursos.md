# Gestión de Recursos y Selección de Modelo

**ID:** DOC-FLU-REC-001
**Versión:** 1.0
**Fecha:** 2026-03-09
**Tipo:** Sistema Core

---

## 1. Propósito

Este sistema gestiona automáticamente:
- **Selección de modelo** óptimo según recursos disponibles
- **Monitorización en tiempo real** de CPU, RAM, GPU
- **Estimación de recursos** antes de ejecutar tareas
- **Estrategia de ejecución** (serie, paralelo, híbrido)
- **Throttling** para evitar ahogar el sistema

---

## 2. Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────────┐
│                    RESOURCE MANAGER                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   Monitor   │  │  Estimator  │  │  Scheduler  │             │
│  │  (Realtime) │──│ (Predictor) │──│ (Dispatcher)│             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│         │                │                │                     │
│         ▼                ▼                ▼                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   RESOURCE STATE                          │  │
│  │  - CPU: 45% used, 55% available                          │  │
│  │  - RAM: 6.2GB used, 9.8GB available                      │  │
│  │  - GPU: No disponible                                     │  │
│  │  - Modelos cargados: llama3.2:3b (2GB)                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Monitor de Recursos (Realtime)

### 3.1 Métricas Recolectadas

```yaml
metrics:
  cpu:
    - usage_percent        # Uso actual %
    - cores_available      # Cores disponibles
    - load_avg_1m          # Load average 1 minuto
    - load_avg_5m          # Load average 5 minutos
    - load_avg_15m         # Load average 15 minutos

  memory:
    - total_gb             # RAM total
    - used_gb              # RAM usada
    - available_gb         # RAM disponible
    - cached_gb            # Caché
    - swap_used_gb         # Swap usado
    - swap_total_gb        # Swap total

  gpu:
    - available            # true/false
    - vram_total_gb        # VRAM total
    - vram_used_gb         # VRAM usada
    - vram_available_gb    # VRAM disponible

  ollama:
    - models_loaded        # Modelos en memoria
    - vram_per_model       # VRAM por modelo
    - inference_active     # ¿Hay inferencia activa?
    - queue_length         # Peticiones en cola

  system:
    - uptime_seconds       # Tiempo encendido
    - process_count        # Número de procesos
    - disk_available_gb    # Disco disponible
```

### 3.2 Implementación del Monitor

```typescript
// /core/resource-manager/monitor.ts

interface SystemResources {
  cpu: CPUInfo;
  memory: MemoryInfo;
  gpu: GPUInfo | null;
  ollama: OllamaInfo;
  timestamp: Date;
}

interface CPUInfo {
  usagePercent: number;
  coresAvailable: number;
  loadAvg1m: number;
  loadAvg5m: number;
  loadAvg15m: number;
}

interface MemoryInfo {
  totalGb: number;
  usedGb: number;
  availableGb: number;
  cachedGb: number;
  swapUsedGb: number;
  swapTotalGb: number;
}

interface GPUInfo {
  available: true;
  vramTotalGb: number;
  vramUsedGb: number;
  vramAvailableGb: number;
}

interface OllamaInfo {
  modelsLoaded: string[];
  vramPerModel: Record<string, number>;
  inferenceActive: boolean;
  queueLength: number;
}

class ResourceMonitor {
  private interval: NodeJS.Timeout | null = null;
  private currentState: SystemResources | null = null;
  private history: SystemResources[] = [];

  async start(intervalMs: number = 1000): Promise<void> {
    this.interval = setInterval(async () => {
      this.currentState = await this.collect();
      this.history.push(this.currentState);

      // Mantener solo últimas 60 muestras (1 minuto)
      if (this.history.length > 60) {
        this.history.shift();
      }
    }, intervalMs);
  }

  private async collect(): Promise<SystemResources> {
    return {
      cpu: await this.getCPUInfo(),
      memory: await this.getMemoryInfo(),
      gpu: await this.getGPUInfo(),
      ollama: await this.getOllamaInfo(),
      timestamp: new Date()
    };
  }

  getCurrentState(): SystemResources | null {
    return this.currentState;
  }

  getAverageUsage(seconds: number): Partial<SystemResources> | null {
    const samples = this.history.slice(-seconds);
    if (samples.length === 0) return null;

    return {
      cpu: {
        usagePercent: this.average(samples.map(s => s.cpu.usagePercent)),
        // ...
      },
      memory: {
        availableGb: Math.min(...samples.map(s => s.memory.availableGb)),
        // ...
      }
    };
  }

  private async getMemoryInfo(): Promise<MemoryInfo> {
    const memInfo = await fs.readFile('/proc/meminfo', 'utf-8');
    // Parsear y calcular GB
    // ...
  }

  private async getOllamaInfo(): Promise<OllamaInfo> {
    try {
      const response = await fetch('http://127.0.0.1:11434/api/ps');
      const data = await response.json();
      return {
        modelsLoaded: data.models?.map((m: any) => m.name) || [],
        vramPerModel: {}, // Calcular
        inferenceActive: data.isRunning || false,
        queueLength: data.queue?.length || 0
      };
    } catch {
      return {
        modelsLoaded: [],
        vramPerModel: {},
        inferenceActive: false,
        queueLength: 0
      };
    }
  }
}
```

---

## 4. Estimador de Recursos

### 4.1 Tabla de Requisitos por Modelo

```yaml
# /config/model-requirements.yaml

models:
  # === OLLAMA LOCAL ===
  llama3.2:1b:
    provider: ollama
    min_ram_gb: 2
    recommended_ram_gb: 3
    vram_gb: 1.3
    inference_time_factor: 0.5    # Relativo a 3B
    concurrent_capacity: 2        # Máximo concurrentes

  llama3.2:3b:
    provider: ollama
    min_ram_gb: 4
    recommended_ram_gb: 6
    vram_gb: 2.0
    inference_time_factor: 1.0
    concurrent_capacity: 1

  llama3.1:8b:
    provider: ollama
    min_ram_gb: 8
    recommended_ram_gb: 12
    vram_gb: 4.7
    inference_time_factor: 2.5
    concurrent_capacity: 1

  mistral:7b:
    provider: ollama
    min_ram_gb: 8
    recommended_ram_gb: 10
    vram_gb: 4.1
    inference_time_factor: 2.2
    concurrent_capacity: 1

  codellama:7b:
    provider: ollama
    min_ram_gb: 8
    recommended_ram_gb: 10
    vram_gb: 3.8
    inference_time_factor: 2.0
    concurrent_capacity: 1

  # === API (sin requisitos locales) ===
  openai-gpt-4:
    provider: openai
    local_resources_required: false
    rate_limit_per_min: 500

  anthropic-claude:
    provider: anthropic
    local_resources_required: false
    rate_limit_per_min: 60
```

### 4.2 Estimador de Tareas

```typescript
// /core/resource-manager/estimator.ts

interface TaskEstimate {
  taskId: string;
  requiredRamGb: number;
  requiredVramGb: number;
  estimatedDurationMs: number;
  parallelizable: boolean;
  priority: 'low' | 'normal' | 'high' | 'critical';
}

interface ModelRequirements {
  minRamGb: number;
  recommendedRamGb: number;
  vramGb: number;
  inferenceTimeFactor: number;
  concurrentCapacity: number;
}

class ResourceEstimator {
  private modelRequirements: Record<string, ModelRequirements>;
  private monitor: ResourceMonitor;

  constructor(monitor: ResourceMonitor) {
    this.monitor = monitor;
    this.modelRequirements = loadModelRequirements();
  }

  /**
   * Estima recursos necesarios para una tarea
   */
  estimateTask(task: Task, modelId: string): TaskEstimate {
    const modelReqs = this.modelRequirements[modelId];
    const taskComplexity = this.assessComplexity(task);

    // RAM base del modelo + overhead de la tarea
    const requiredRamGb = modelReqs.recommendedRamGb + taskComplexity.memoryOverheadGb;

    // VRAM del modelo
    const requiredVramGb = modelReqs.vramGb;

    // Duración estimada
    const baseDuration = this.estimateBaseDuration(task);
    const estimatedDurationMs = baseDuration * modelReqs.inferenceTimeFactor;

    return {
      taskId: task.id,
      requiredRamGb,
      requiredVramGb,
      estimatedDurationMs,
      parallelizable: taskComplexity.parallelizable,
      priority: task.priority
    };
  }

  /**
   * Verifica si una tarea puede ejecutarse
   */
  canExecute(estimate: TaskEstimate): {
    canExecute: boolean;
    reason?: string;
    suggestedModel?: string;
    waitTimeMs?: number;
  } {
    const state = this.monitor.getCurrentState();
    if (!state) {
      return { canExecute: false, reason: 'Monitor not initialized' };
    }

    // Verificar RAM
    const availableRamGb = state.memory.availableGb;
    if (availableRamGb < estimate.requiredRamGb) {
      // Buscar modelo más pequeño
      const smallerModel = this.findSmallerModel(estimate.requiredRamGb);
      if (smallerModel) {
        return {
          canExecute: false,
          reason: `RAM insuficiente (${availableRamGb}GB < ${estimate.requiredRamGb}GB)`,
          suggestedModel: smallerModel
        };
      }

      return {
        canExecute: false,
        reason: `RAM insuficiente y no hay modelo alternativo`,
        waitTimeMs: this.estimateWaitTime(estimate.requiredRamGb - availableRamGb)
      };
    }

    // Verificar si ya hay inferencia activa
    if (state.ollama.inferenceActive) {
      return {
        canExecute: false,
        reason: 'Inferencia activa en progreso',
        waitTimeMs: 5000 // Reintentar en 5s
      };
    }

    return { canExecute: true };
  }

  /**
   * Estima tiempo de espera hasta que haya recursos
   */
  private estimateWaitTime(ramNeededGb: number): number {
    const state = this.monitor.getCurrentState();
    if (!state) return 30000; // Default 30s

    // Estimar basado en tareas actuales
    // Simplificado: 10s por GB necesario
    return Math.max(10000, ramNeededGb * 10000);
  }

  /**
   * Encuentra modelo más pequeño que quepa
   */
  private findSmallerModel(maxRamGb: number): string | null {
    const available = state.memory.availableGb;
    const candidates = Object.entries(this.modelRequirements)
      .filter(([_, reqs]) => reqs.recommendedRamGb <= available)
      .sort((a, b) => a[1].recommendedRamGb - b[1].recommendedRamGb);

    return candidates.length > 0 ? candidates[0][0] : null;
  }
}
```

---

## 5. Planificador (Scheduler)

### 5.1 Estrategias de Ejecución

```typescript
// /core/resource-manager/scheduler.ts

type ExecutionStrategy =
  | 'serial'           // Una tarea tras otra
  | 'parallel'         // Todas a la vez
  | 'batch'            // En grupos (batches)
  | 'adaptive'         // Según recursos disponibles
  | 'priority_first';  // Ordenar por prioridad

interface SchedulingDecision {
  strategy: ExecutionStrategy;
  tasks: {
    taskId: string;
    modelId: string;
    startAfter: string | null;  // ID de tarea anterior (para serial)
    batch?: number;
  }[];
  estimatedTotalTimeMs: number;
  resourceUtilization: {
    peakRamGb: number;
    peakVramGb: number;
  };
}

class ResourceScheduler {
  private monitor: ResourceMonitor;
  private estimator: ResourceEstimator;

  /**
   * Decide la estrategia óptima para un conjunto de tareas
   */
  schedule(tasks: Task[], preferences?: SchedulingPreferences): SchedulingDecision {
    const estimates = tasks.map(t => ({
      task: t,
      estimate: this.estimator.estimateTask(t, t.preferredModel || 'llama3.2:3b')
    }));

    const state = this.monitor.getCurrentState();

    // Decidir estrategia
    const strategy = this.selectStrategy(estimates, state, preferences);

    // Generar plan
    switch (strategy) {
      case 'serial':
        return this.planSerial(estimates);
      case 'parallel':
        return this.planParallel(estimates, state);
      case 'batch':
        return this.planBatch(estimates, state);
      case 'adaptive':
        return this.planAdaptive(estimates, state);
      case 'priority_first':
        return this.planPriorityFirst(estimates);
    }
  }

  private selectStrategy(
    estimates: EstimatedTask[],
    state: SystemResources | null,
    preferences?: SchedulingPreferences
  ): ExecutionStrategy {
    if (!state) return 'serial';

    // Calcular recursos totales necesarios para paralelo
    const totalRamNeeded = estimates.reduce(
      (sum, e) => sum + e.estimate.requiredRamGb,
      0
    );

    const availableRam = state.memory.availableGb;

    // Decisión basada en recursos
    if (totalRamNeeded <= availableRam * 0.7) {
      // Recursos suficientes para todo en paralelo
      return 'parallel';
    } else if (totalRamNeeded <= availableRam) {
      // Recursos ajustados, usar batches
      return 'batch';
    } else {
      // Recursos insuficientes, serial
      return 'serial';
    }
  }

  private planParallel(estimates: EstimatedTask[]): SchedulingDecision {
    return {
      strategy: 'parallel',
      tasks: estimates.map(e => ({
        taskId: e.task.id,
        modelId: e.task.preferredModel || 'llama3.2:3b',
        startAfter: null
      })),
      estimatedTotalTimeMs: Math.max(...estimates.map(e => e.estimate.estimatedDurationMs)),
      resourceUtilization: {
        peakRamGb: estimates.reduce((sum, e) => sum + e.estimate.requiredRamGb, 0),
        peakVramGb: estimates.reduce((sum, e) => sum + e.estimate.requiredVramGb, 0)
      }
    };
  }

  private planBatch(estimates: EstimatedTask[], state: SystemResources): SchedulingDecision {
    const availableRam = state.memory.availableGb;
    const batches: EstimatedTask[][] = [];
    let currentBatch: EstimatedTask[] = [];
    let currentBatchRam = 0;

    // Agrupar en batches que quepan en RAM
    for (const estimate of estimates) {
      if (currentBatchRam + estimate.estimate.requiredRamGb <= availableRam * 0.8) {
        currentBatch.push(estimate);
        currentBatchRam += estimate.estimate.requiredRamGb;
      } else {
        if (currentBatch.length > 0) {
          batches.push(currentBatch);
        }
        currentBatch = [estimate];
        currentBatchRam = estimate.estimate.requiredRamGb;
      }
    }

    if (currentBatch.length > 0) {
      batches.push(currentBatch);
    }

    // Generar plan
    const tasks: SchedulingDecision['tasks'] = [];
    let previousTaskId: string | null = null;

    batches.forEach((batch, batchIndex) => {
      // Dentro de un batch, pueden ir en paralelo
      batch.forEach(estimate => {
        tasks.push({
          taskId: estimate.task.id,
          modelId: estimate.task.preferredModel || 'llama3.2:3b',
          startAfter: batchIndex === 0 ? null : batches[batchIndex - 1][0].task.id,
          batch: batchIndex
        });
      });
    });

    // Calcular tiempo total
    const totalTime = batches.reduce((sum, batch) => {
      const batchTime = Math.max(...batch.map(e => e.estimate.estimatedDurationMs));
      return sum + batchTime;
    }, 0);

    return {
      strategy: 'batch',
      tasks,
      estimatedTotalTimeMs: totalTime,
      resourceUtilization: {
        peakRamGb: availableRam * 0.8,
        peakVramGb: Math.max(...batches.flat().map(e => e.estimate.requiredVramGb))
      }
    };
  }

  private planSerial(estimates: EstimatedTask[]): SchedulingDecision {
    const tasks: SchedulingDecision['tasks'] = [];
    let previousTaskId: string | null = null;

    estimates.forEach(estimate => {
      tasks.push({
        taskId: estimate.task.id,
        modelId: estimate.task.preferredModel || 'llama3.2:3b',
        startAfter: previousTaskId
      });
      previousTaskId = estimate.task.id;
    });

    return {
      strategy: 'serial',
      tasks,
      estimatedTotalTimeMs: estimates.reduce(
        (sum, e) => sum + e.estimate.estimatedDurationMs,
        0
      ),
      resourceUtilization: {
        peakRamGb: Math.max(...estimates.map(e => e.estimate.requiredRamGb)),
        peakVramGb: Math.max(...estimates.map(e => e.estimate.requiredVramGb))
      }
    };
  }
}
```

---

## 6. Políticas de Recursos

### 6.1 Configuración de Políticas

```yaml
# /config/resource-policies.yaml

policies:
  # === UMBRALES DE SEGURIDAD ===
  thresholds:
    ram:
      min_available_gb: 1           # Mínimo RAM libre SIEMPRE
      max_usage_percent: 85         # No usar más del 85%
      critical_available_gb: 0.5    # Emergencia: liberar recursos

    cpu:
      max_usage_percent: 90
      max_load_factor: 2.0          # Load avg no más de 2x cores

    ollama:
      max_queue_length: 10          # Máximo en cola
      max_concurrent_models: 2       # Máximo modelos cargados
      inference_timeout_ms: 300000   # 5 minutos máximo

  # === SELECCIÓN AUTOMÁTICA DE MODELO ===
  model_selection:
    strategy: adaptive               # auto | fixed | adaptive

    rules:
      # Si RAM < 4GB, usar modelo pequeño
      - condition: "ram_available_gb < 4"
        model: "llama3.2:1b"

      # Si RAM 4-8GB, usar 3B
      - condition: "ram_available_gb >= 4 && ram_available_gb < 8"
        model: "llama3.2:3b"

      # Si RAM >= 8GB, permitir 8B
      - condition: "ram_available_gb >= 8"
        model: "llama3.1:8b"

    # Fallback a API si recursos insuficientes
    api_fallback:
      enabled: true
      provider: openai                # openai | anthropic
      model: gpt-4o-mini
      trigger: "ram_available_gb < 2"

  # === ESTRATEGIA DE EJECUCIÓN ===
  execution:
    default_strategy: adaptive       # serial | parallel | batch | adaptive

    parallel:
      max_concurrent: 3              # Máximo tareas paralelas
      min_ram_per_task_gb: 2         # RAM mínima por tarea

    batch:
      batch_size: auto               # auto | número fijo
      batch_delay_ms: 1000           # Pausa entre batches

    serial:
      task_delay_ms: 100             # Pausa entre tareas

  # === PRIORIDADES ===
  priority:
    levels:
      critical:
        preempt_lower: true          # Puede desplazar tareas de menor prioridad
        max_wait_ms: 0               # Sin espera

      high:
        preempt_lower: false
        max_wait_ms: 5000

      normal:
        max_wait_ms: 30000

      low:
        max_wait_ms: 300000          # 5 minutos

  # === THROTTLING ===
  throttling:
    enabled: true
    cooldown_ms: 1000                # Pausa entre peticiones

    backoff:
      strategy: exponential          # linear | exponential
      initial_ms: 1000
      max_ms: 60000
      multiplier: 2

  # === DESCARGA DE MODELOS ===
  model_unload:
    enabled: true
    idle_timeout_ms: 300000          # 5 minutos sin uso
    keep_models: ["llama3.2:3b"]     # Modelos a mantener cargados
```

### 6.2 Aplicador de Políticas

```typescript
// /core/resource-manager/policy-enforcer.ts

class PolicyEnforcer {
  private policies: ResourcePolicies;
  private monitor: ResourceMonitor;

  /**
   * Verifica si una acción cumple las políticas
   */
  checkCompliance(action: ResourceAction): ComplianceResult {
    const state = this.monitor.getCurrentState();
    const violations: string[] = [];

    // Verificar umbral de RAM
    if (state.memory.availableGb - action.ramNeeded < this.policies.thresholds.ram.min_available_gb) {
      violations.push(`Violación: RAM disponible caería por debajo de ${this.policies.thresholds.ram.min_available_gb}GB`);
    }

    // Verificar uso máximo
    const projectedUsage = ((state.memory.usedGb + action.ramNeeded) / state.memory.totalGb) * 100;
    if (projectedUsage > this.policies.thresholds.ram.max_usage_percent) {
      violations.push(`Uso de RAM proyectado (${projectedUsage.toFixed(1)}%) excede máximo (${this.policies.thresholds.ram.max_usage_percent}%)`);
    }

    // Verificar cola de Ollama
    if (state.ollama.queueLength >= this.policies.thresholds.ollama.max_queue_length) {
      violations.push(`Cola de Ollama llena (${state.ollama.queueLength}/${this.policies.thresholds.ollama.max_queue_length})`);
    }

    return {
      compliant: violations.length === 0,
      violations,
      recommendation: violations.length > 0 ? this.recommendAlternative(action, state) : null
    };
  }

  /**
   * Recomienda alternativa cuando hay violación
   */
  private recommendAlternative(action: ResourceAction, state: SystemResources): AlternativeRecommendation {
    // 1. Intentar modelo más pequeño
    const smallerModel = this.findSmallerModel(action.ramNeeded, state);
    if (smallerModel) {
      return {
        type: 'smaller_model',
        modelId: smallerModel.modelId,
        savingsRamGb: action.ramNeeded - smallerModel.ramNeeded
      };
    }

    // 2. Sugerir API fallback
    if (this.policies.model_selection.api_fallback.enabled) {
      return {
        type: 'api_fallback',
        provider: this.policies.model_selection.api_fallback.provider,
        model: this.policies.model_selection.api_fallback.model
      };
    }

    // 3. Sugerir esperar
    return {
      type: 'wait',
      estimatedWaitMs: this.estimateWaitTime(action, state)
    };
  }

  /**
   * Selecciona modelo óptimo según políticas
   */
  selectModel(task: Task): string {
    const state = this.monitor.getCurrentState();

    for (const rule of this.policies.model_selection.rules) {
      if (this.evaluateCondition(rule.condition, state)) {
        return rule.model;
      }
    }

    // Fallback
    return 'llama3.2:3b';
  }

  /**
   * Ejecuta throttling si es necesario
   */
  async enforceThrottle(): Promise<void> {
    if (!this.policies.throttling.enabled) return;

    const state = this.monitor.getCurrentState();
    const usagePercent = (state.memory.usedGb / state.memory.totalGb) * 100;

    if (usagePercent > 80) {
      const delay = this.calculateBackoff(usagePercent);
      await sleep(delay);
    }
  }
}
```

---

## 7. Integración con Tri-Agente

### 7.1 Flujo de Decisión

```
Director recibe tarea
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│  POLICY ENFORCER                                                 │
│  1. Evaluar complejidad de tarea                                │
│  2. Consultar políticas                                          │
│  3. Seleccionar modelo óptimo                                    │
│  4. Verificar recursos disponibles                               │
└─────────────────────────────────────────────────────────────────┘
        │
        ├── Recursos OK → Ejecutar
        │
        ├── Recursos insuficientes →
        │   ├── Modelo más pequeño?
        │   ├── API fallback?
        │   └── Esperar?
        │
        └── Crítico → Desplazar tareas de baja prioridad
```

### 7.2 Modificación del Ejecutor

```typescript
// En Ejecutor, antes de ejecutar:

async execute(task: Task): Promise<Result> {
  // 1. Verificar políticas
  const compliance = this.policyEnforcer.checkCompliance({
    ramNeeded: this.estimateRamNeeded(task),
    modelId: task.preferredModel
  });

  if (!compliance.compliant) {
    // Aplicar recomendación
    if (compliance.recommendation?.type === 'smaller_model') {
      task.model = compliance.recommendation.modelId;
    } else if (compliance.recommendation?.type === 'api_fallback') {
      return this.executeViaAPI(task, compliance.recommendation);
    } else if (compliance.recommendation?.type === 'wait') {
      await sleep(compliance.recommendation.estimatedWaitMs);
    }
  }

  // 2. Aplicar throttle si necesario
  await this.policyEnforcer.enforceThrottle();

  // 3. Ejecutar
  return this.doExecute(task);
}
```

---

## 8. API de Recursos

### 8.1 Endpoints

```yaml
# API REST para monitoreo

GET /api/v1/resources/current
  response:
    cpu: {...}
    memory: {...}
    ollama: {...}

GET /api/v1/resources/history?minutes=5
  response: ResourceSnapshot[]

GET /api/v1/resources/estimate
  body:
    task: Task
    model: string
  response:
    requiredRamGb: number
    canExecute: boolean
    recommendation: {...}

POST /api/v1/resources/gc
  description: Forzar garbage collection de modelos

GET /api/v1/resources/models/loaded
  response: Model[]

DELETE /api/v1/resources/models/{modelId}
  description: Descargar modelo de memoria
```

---

## 9. Métricas y Alertas

### 9.1 Métricas Emitidas

```yaml
metrics:
  # Cada segundo
  - name: openclaw.resource.ram.available_gb
    type: gauge

  - name: openclaw.resource.ram.used_percent
    type: gauge

  - name: openclaw.resource.cpu.usage_percent
    type: gauge

  - name: openclaw.resource.ollama.models_loaded
    type: gauge

  - name: openclaw.resource.ollama.queue_length
    type: gauge

  # Por ejecución
  - name: openclaw.resource.execution.strategy
    type: label

  - name: openclaw.resource.execution.estimated_time_ms
    type: gauge

  - name: openclaw.resource.execution.actual_time_ms
    type: gauge

  - name: openclaw.resource.throttle.events
    type: counter
```

### 9.2 Alertas

```yaml
alerts:
  - name: HighMemoryUsage
    condition: "ram_used_percent > 90"
    severity: warning
    message: "Uso de RAM alto: {{value}}%"

  - name: CriticalMemoryUsage
    condition: "ram_used_percent > 95"
    severity: critical
    message: "Memoria crítica: {{value}}%"
    action: trigger_gc

  - name: OllamaQueueFull
    condition: "ollama.queue_length >= 10"
    severity: warning
    message: "Cola de Ollama llena"

  - name: ModelLoadFailed
    condition: "model_load_failed"
    severity: error
    message: "Error cargando modelo {{model}}"
```

---

## 10. Ejemplo de Uso

### 10.1 Escenario: 3 Tareas Simultáneas

```yaml
# Tareas entrantes
tasks:
  - id: task-1
    type: code_generation
    priority: high
    estimated_ram_gb: 3

  - id: task-2
    type: code_review
    priority: normal
    estimated_ram_gb: 2

  - id: task-3
    type: documentation
    priority: low
    estimated_ram_gb: 2

# Estado del sistema
system:
  ram_total_gb: 16
  ram_used_gb: 8
  ram_available_gb: 8

# Decisión del Scheduler
decision:
  strategy: batch

  batch_1:
    tasks: [task-1, task-2]
    ram_needed: 5GB
    reason: "Ambas caben en RAM disponible"

  batch_2:
    tasks: [task-3]
    ram_needed: 2GB
    reason: "Tarea de baja prioridad, esperar a batch_1"

  estimated_total_time: 45s
  # vs. serial: 60s
  # vs. parallel: 30s (pero excedería RAM)
```

---

**Documento:** Sistema de Gestión de Recursos y Selección de Modelo
**ID:** SYS-RES-001
**Versión:** 1.0
