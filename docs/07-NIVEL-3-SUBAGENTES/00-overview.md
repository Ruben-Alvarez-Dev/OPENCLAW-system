# Nivel 3 - Subagentes Efímeros

**ID:** DOC-SUB-OVE-001
**Tipo:** Trabajadores Temporales | **Función:** Ejecución paralela de tareas específicas
**Versión:** 2.1.0
**Fecha:** 2026-03-09

---

## Concepto

Los **Subagentes Efímeros** son trabajadores temporales que se crean bajo demanda para ejecutar tareas específicas y **mueren al completar su trabajo**. No tienen memoria persistente y son el mecanismo de escalado horizontal del sistema.

---

## Características

| Característica | Descripción |
|----------------|-------------|
| **Vida útil** | Limitada a la duración de la tarea |
| **Memoria** | Sin persistencia, solo contexto de tarea |
| **Creación** | Bajo demanda, según necesidad |
| **Destrucción** | Automática al completar |
| **Supervisión** | Mínima, reportan a unidad especialista |
| **Coste** | Bajo, solo recursos durante ejecución |

---

## Cuándo Se Usan

### Casos de Uso

| Caso | Ejemplo |
|------|---------|
| **Procesamiento masivo** | "Procesar 1000 documentos" |
| **Consultas paralelas** | "Buscar en 5 APIs diferentes" |
| **Tareas de compilación** | "Build de 10 microservicios" |
| **Análisis de datos** | "Analizar 100 archivos CSV" |
| **Generación bulk** | "Crear 50 configuraciones" |

### Cuándo NO Se Usan

- Decisiones que requieren memoria
- Tareas que necesitan validación interna
- Operaciones que afectan estado del sistema
- Peticiones que requieren trazabilidad completa

---

## Estructura

```
UNIDAD ESPECIALISTA (Nivel 2)
│
├── Director
│   └── Detecta necesidad de subagentes
│
├── Ejecutor
│   └── Coordina subagentes
│
└── Subagentes Efímeros (Nivel 3)
    │
    ├── Subagente #1 ──── Ejecuta tarea ──── Muere
    ├── Subagente #2 ──── Ejecuta tarea ──── Muere
    ├── Subagente #3 ──── Ejecuta tarea ──── Muere
    └── ...
```

---

## Flujo de Creación y Destrucción

```
┌─────────────────────────────────────────────────────────────────┐
│  1. UNIDAD RECIBE TAREA MASIVA                                  │
│     "Procesar 1000 documentos"                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. DIRECTOR DECIDE ESCALAR                                     │
│     - Divide en 100 lotes de 10 documentos                      │
│     - Solicita 10 subagentes                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. SPAWN DE SUBAGENTES                                         │
│     ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                   │
│     │ SA1 │ │ SA2 │ │ SA3 │ │ SA4 │ │ SA5 │ ...               │
│     └─────┘ └─────┘ └─────┘ └─────┘ └─────┘                   │
│     Cada uno recibe: lote de documentos + instrucciones         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. EJECUCIÓN PARALELA                                          │
│     SA1: docs 1-10    → resultado1                             │
│     SA2: docs 11-20   → resultado2                             │
│     SA3: docs 21-30   → resultado3                             │
│     ...                                                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. RECOLECCIÓN Y MUERTE                                        │
│     Ejecutor recopila resultados                                │
│     Subagentes son destruidos                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  6. CONSOLIDACIÓN Y VALIDACIÓN                                  │
│     Archivador valida resultados consolidados                   │
│     Output final entregado                                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Configuración

```yaml
subagents:
  # Límites de recursos
  max_concurrent: 50          # Máximo simultáneos
  max_per_request: 20        # Máximo por petición
  timeout: 300000            # 5 minutos max vida

  # Recursos por subagente
  resources:
    memory: 256m
    cpu: 0.5

  # Política de spawn
  spawn_policy:
    strategy: "batch"        # batch, stream, adaptive
    batch_size: 10
    cooldown: 1000           # ms entre spawns
```

---

## Tipos de Subagentes

### Por Función

| Tipo | Función | Herramientas |
|------|---------|--------------|
| **Processor** | Procesamiento de datos | filesystem, shell |
| **Fetcher** | Obtener datos externos | http-client |
| **Generator** | Generar contenido | llm, templates |
| **Analyzer** | Análisis específico | llm, calculators |
| **Validator** | Validación masiva | validators |

### Por Recursos

| Nivel | Memoria | CPU | Timeout |
|-------|---------|-----|---------|
| **Light** | 128m | 0.25 | 60s |
| **Standard** | 256m | 0.5 | 300s |
| **Heavy** | 512m | 1.0 | 600s |

---

## Comunicación

### Con Unidad Especialista

```
Subagente → Ejecutor: Reporte de progreso
Ejecutor → Subagente: Instrucciones adicionales
Subagente → Ejecutor: Resultado final
```

### Formato de Mensaje

```json
{
  "type": "subagent_result",
  "subagent_id": "sa-uuid-123",
  "parent_unit": "dev-unit",
  "status": "completed",
  "result": { ... },
  "metrics": {
    "duration_ms": 1523,
    "items_processed": 10
  }
}
```

---

## Limitaciones

| Limitación | Razón |
|------------|-------|
| Sin memoria persistente | Eficiencia y simplicidad |
| Sin validación interna | Velocidad de ejecución |
| Sin acceso a Vault | Seguridad |
| Timeout estricto | Prevención de zombies |
| Sin comunicación inter-subagente | Aislamiento |

---

## Métricas

| Métrica | Descripción |
|---------|-------------|
| `subagents.spawned.total` | Subagentes creados |
| `subagents.active.current` | Subagentes activos ahora |
| `subagents.completed.total` | Completados exitosamente |
| `subagents.failed.total` | Fallos |
| `subagents.avg_lifetime` | Vida promedio en ms |

---

## Ejemplo de Uso

### Petición
```
Usuario: "Analizar los 50 archivos CSV en /data y generar resumen"
```

### Proceso
```
1. Unidad DES recibe petición
2. Director divide: 5 lotes de 10 archivos
3. Ejecutor genera 5 subagentes
4. Cada subagente:
   - Lee sus 10 CSVs
   - Extrae estadísticas
   - Retorna resultado
   - Muere
5. Ejecutor consolida resultados
6. Archivador valida
7. Output entregado
```

---

**Documento:** Nivel 3 - Subagentes Efímeros
**Ubicación:** `docs/07-NIVEL-3-SUBAGENTES/00-overview.md`
**Versión:** 2.1.0
**Fecha:** 2026-03-09
