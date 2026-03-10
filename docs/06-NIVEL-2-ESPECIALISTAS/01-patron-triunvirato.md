# Patrón Triunvirato (Tri-Agente)

**ID:** DOC-ESP-PAT-001
**Nivel:** ESP - Especialistas
**Tipo:** Patrón Arquitectónico
**Versión:** 2.1.0
**Fecha:** 2026-03-09

---

## Resumen

El **Patrón Triunvirato** (o Tri-Agente) es la unidad fundamental de ejecución en OPENCLAW. Cada especialista está compuesto por tres agentes con roles complementarios que se validan mutuamente, proporcionando robustez y calidad garantizada.

---

## Los Tres Roles

### Director (Planificador)

```
┌─────────────────────────────────────────┐
│               DIRECTOR                   │
│                                         │
│  • Recibe solicitudes del usuario       │
│  • Analiza requisitos                   │
│  • Consulta memoria histórica           │
│  • Planifica enfoque de solución        │
│  • Delega al Ejecutor                   │
│  • Revisa output antes de entregar      │
└─────────────────────────────────────────┘
```

**Características:**
- Temperatura alta (0.7) para creatividad en planificación
- Sin herramientas de ejecución directa
- Visión global de la tarea
- Responsable de la calidad final

### Ejecutor (Implementador)

```
┌─────────────────────────────────────────┐
│               EJECUTOR                   │
│                                         │
│  • Recibe plan del Director             │
│  • Ejecuta tareas específicas           │
│  • Genera código/documentos/soluciones  │
│  • Accede a herramientas                 │
│  • Aplica validaciones básicas          │
└─────────────────────────────────────────┘
```

**Características:**
- Temperatura baja (0.3) para precisión
- Acceso a herramientas de ejecución
- Sandbox para operaciones peligrosas
- Especializado en el dominio

### Archivador (Validador)

```
┌─────────────────────────────────────────┐
│              ARCHIVADOR                  │
│                                         │
│  • Recibe output del Ejecutor           │
│  • Valida calidad y coherencia          │
│  • Documenta decisiones                 │
│  • Actualiza memoria                    │
│  • Indexa para búsqueda semántica       │
│  • Aprobar o rechazar output            │
└─────────────────────────────────────────┘
```

**Características:**
- Temperatura muy baja (0.1) para consistencia
- Acceso a memoria persistente
- Criterios de validación estrictos
- Responsable del aprendizaje del sistema

---

## Flujo de Ejecución

```
┌──────────────────────────────────────────────────────────────────┐
│                         REQUEST                                   │
│                    (Usuario → Sistema)                           │
└──────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                         DIRECTOR                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ 1. Recibir request                                          │ │
│  │ 2. Analizar requisitos                                      │ │
│  │ 3. Consultar memoria (¿soluciones previas similares?)       │ │
│  │ 4. Evaluar complejidad                                      │ │
│  │ 5. Definir plan de implementación                           │ │
│  │ 6. Preparar contexto para Ejecutor                          │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
                                │
                    Delegación con contexto
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                         EJECUTOR                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ 1. Recibir plan del Director                                │ │
│  │ 2. Ejecutar tareas                                          │ │
│  │ 3. Generar output (código, documento, etc.)                 │ │
│  │ 4. Auto-validación básica                                   │ │
│  │ 5. Entregar al Archivador                                   │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
                                │
                        Output generado
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                        ARCHIVADOR                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ 1. Recibir output del Ejecutor                              │ │
│  │ 2. Validación sintáctica                                    │ │
│  │ 3. Validación semántica                                     │ │
│  │ 4. Validación de calidad                                    │ │
│  │ 5. Validación de seguridad                                  │ │
│  │                                                             │ │
│  │    ┌─────────────┐    ┌─────────────┐                      │ │
│  │    │ PASS        │    │ FAIL        │                      │ │
│  │    │ → Archivar  │    │ → Rechazar  │                      │ │
│  │    │ → Retornar  │    │ → Reintentar│                      │ │
│  │    └─────────────┘    └─────────────┘                      │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
                                │
                        Output validado
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                         DIRECTOR                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ 1. Revisar output validado                                  │ │
│  │ 2. Aprobación final                                         │ │
│  │ 3. Entregar al usuario                                      │ │
│  │ 4. Actualizar métricas                                      │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                        RESPONSE                                   │
│                    (Sistema → Usuario)                           │
└──────────────────────────────────────────────────────────────────┘
```

---

## Mecanismo de Consenso

### Tipos de Decisión

| Tipo | Umbral | Descripción |
|------|--------|-------------|
| Normal | 2/3 (66%) | Tareas estándar |
| Crítica | 3/3 (100%) | Operaciones destructivas, seguridad |

### Indicadores de Tarea Crítica

```yaml
indicadores_criticos:
  - operaciones_destructivas
  - cambios_seguridad
  - despliegues_produccion
  - modificaciones_datos
  - cambios_credenciales
  - cambios_infraestructura
```

### Proceso de Consenso

```python
def alcanzar_consenso(output: Output, tipo_tarea: TipoTarea) -> ResultadoConsenso:
    votos = []

    # Voto del Director
    votos.append(director.revisar(output))

    # Voto del Ejecutor (auto-validación)
    votos.append(ejecutor.validar(output))

    # Voto del Archivador
    votos.append(archivador.validar(output))

    umbral = 1.0 if tipo_tarea.es_critico else 0.66

    if sum(votos) / len(votos) >= umbral:
        return ResultadoConsenso.APROBADO
    else:
        return ResultadoConsenso.RECHAZADO
```

---

## Manejo de Errores

### Validación Fallida

```
Output → Archivador → FAIL
              │
              ▼
        ¿Max reintentos?
         /      \
        NO      SI
        │        │
        ▼        ▼
    Retornar a   Escalar
    Ejecutor     al Director
        │
        ▼
    Reintentar con
    feedback
```

### Timeout

```
Tarea → Timeout → Cancelar → Notificar Director → Log → Fallback
```

### Consenso Fallido

```
Votos: [PASS, PASS, FAIL]
          │
          ▼
    Director decide
    (autoridad final)
```

---

## Configuración por Dominio

### Ejemplo: ESP-DES (Desarrollo)

```yaml
tri_agente:
  director:
    modelo: glm-4.5-air
    temperatura: 0.7
    max_tokens: 4096

  ejecutor:
    modelo: glm-4.5-air
    temperatura: 0.3
    max_tokens: 8192
    herramientas: [shell-exec, filesystem, git, docker-cli]

  archivador:
    modelo: glm-4.5-air
    temperatura: 0.1
    max_tokens: 4096
    herramientas: [memory-writer, embedding-generator]

  consenso:
    umbral: 0.66
    umbral_critico: 1.0
    timeout_ms: 60000
```

### Ejemplo: ESP-INF (Infraestructura - más conservador)

```yaml
tri_agente:
  director:
    modelo: glm-4.5-air
    temperatura: 0.5  # Menos creatividad, más seguridad

  ejecutor:
    modelo: glm-4.5-air
    temperatura: 0.2  # Máxima precisión
    herramientas:
      - nombre: shell-exec
        requiere_aprobacion: true  # Siempre requiere approval

  consenso:
    umbral: 0.66
    umbral_critico: 1.0
    timeout_ms: 120000  # Más tiempo para operaciones complejas
```

---

## Beneficios del Patrón

### 1. Calidad Garantizada

- Triple validación antes de entregar
- Reducción de errores ~90% vs agente simple

### 2. Trazabilidad

- Cada paso documentado
- Memoria persistente de decisiones
- Auditoría completa

### 3. Especialización

- Cada rol optimizado para su función
- Prompts específicos por tarea
- Herramientas selectivas

### 4. Resiliencia

- Si un agente falla, otros compensan
- Mecanismo de reintento automático
- Escalamiento claro

### 5. Aprendizaje Continuo

- Archivador aprende de cada interacción
- Memoria compartida mejora con el tiempo
- Evolución de prompts basada en datos

---

## Antipatrones a Evitar

| Antipatrón | Problema | Solución |
|------------|----------|----------|
| Director ejecutando | Pierde visión global | Director solo planifica |
| Ejecutor sin validación | Errores en output | Siempre pasar por Archivador |
| Archivador aprobando todo | Sin validación real | Criterios estrictos |
| Sin memoria | Repite errores | Siempre actualizar memoria |
| Timeout muy corto | Tareas incompletas | Ajustar por dominio |

---

## Métricas del Tri-Agente

| Métrica | Fórmula | Objetivo |
|---------|---------|----------|
| Tasa de Consenso | Aprobados unánimes / Total | > 80% |
| Tasa de Reintentos | Reintentos / Total peticiones | < 10% |
| Tasa de Validación | Pass primera vez / Total | > 85% |
| Tiempo Promedio | Tiempo total / Petición | < 60s |

---

## Extensibilidad

### Añadir Nuevo Agente (no recomendado)

```yaml
# Solo para casos muy específicos
tri_agente:
  # ... agentes existentes ...

  revisor:  # Agente adicional
    modelo: glm-4.5-air
    rol: revision_seguridad
    disparadores: [despliegue_produccion]
```

### Personalizar por Tarea

```python
def configurar_tri_agente(tarea: Tarea) -> ConfigTriAgente:
    if tarea.requiere_revision_seguridad:
        config.consenso.umbral = 1.0
        config.archivador.validacion_extra = ["seguridad"]

    if tarea.es_creativa:
        config.director.temperatura = 0.9
        config.consenso.umbral = 0.5

    return config
```

---

## Referencias

- [00-overview.md](./00-overview.md) - Visión general de Nivel ESP
- [02-unidades-disponibles.md](./02-unidades-disponibles.md) - Unidades disponibles
- [03-agent-factory.md](./03-agent-factory.md) - Fábrica de Agentes
- [../05-NIVEL-1-CATEDRATICOS/00-overview.md](../05-NIVEL-1-CATEDRATICOS/00-overview.md) - Catedráticos
- [biblioteca/plantillas/SIS-BIB-PLA-002-triagente_estandar.yaml](../../biblioteca/plantillas/SIS-BIB-PLA-002-triagente_estandar.yaml) - Plantilla estándar

---

**Documento:** Patrón Triunvirato
**Ubicación:** `docs/06-NIVEL-2-ESPECIALISTAS/01-patron-triunvirato.md`
**Versión:** 2.1.0
**Fecha:** 2026-03-09
