# El Concilio Tri-Agente: Patrón Arquitectónico

**Propietario:** Ruben
**Fecha:** 2026-03-10
**Tipo:** Arquitectura Core - Documentación Técnica
**Versión:** 3.0

---

## Resumen Ejecutivo

El **Concilio Tri-Agente** es el bloque de construcción fundamental del sistema OPENCLAW-system. Es un patrón arquitectónico donde **3 procesos especializados** trabajan en coordinación para producir salidas estables y verificadas.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CAPA DE COMUNICACIÓN                             │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Redis Pub/Sub (mensajes estructurados)                         │   │
│  │  Memoria Compartida (estado efímero)                            │   │
│  │  RAG Compartido (conocimiento validado)                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       3 PROCESOS ESPECIALIZADOS                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │   │
│  │  │  DIRECTOR   │  │  EJECUTOR   │  │ ARCHIVADOR  │             │   │
│  │  │  Proceso    │◄─┤  Proceso    │◄─┤  Proceso    │             │   │
│  │  │  Node.js    │  │  Node.js    │  │  Node.js    │             │   │
│  │  │  Puerto     │  │  Puerto     │  │  Puerto     │             │   │
│  │  │  8081       │  │  8082       │  │  8083       │             │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘             │   │
│  │         │                │                │                     │   │
│  │         └────────────────┴────────────────┘                     │   │
│  │                   Redis Pub/Sub                                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                          Usuario (Telegram/Discord)
```

---

## Arquitectura en Dos Capas

### Capa 1: Procesos Especializados

Cada agente es un **proceso Node.js independiente** con:

| Componente | Descripción |
|------------|-------------|
| **Puerto propio** | HTTP server para health checks y métricas |
| **Modelo LLM propio** | Optimizado para su rol específico |
| **Workspace propio** | Archivos, prompts, skills |
| **Memoria propia** | Base vectorial individual |
| **Herramientas propias** | Según su especialización |

### Capa 2: Infraestructura de Comunicación

| Componente | Tecnología | Propósito |
|------------|------------|-----------|
| **Redis Pub/Sub** | Redis | Comunicación estructurada entre agentes |
| **Memoria Compartida** | Redis | Estado efímero del concilio |
| **RAG Compartido** | LanceDB | Conocimiento validado compartido |
| **Cola de Tareas** | BullMQ | Gestión de tareas async |

---

## Arquitectura Fractal Recursiva

### Principio Fundamental

**Cada nivel se comporta como UNA SOLA entidad desde la perspectiva del nivel superior.**

```
NIVEL 0 (Usuario)
    │
    ▼
┌────────────────────────────────────────────────────────────┐
│  CONCILIO (vista como unidad única)                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  NIVEL L2: CONCILIO TRI-AGENTE                        │  │
│  │  ┌────────────┬────────────┬────────────┐            │  │
│  │  │  DIRECTOR  │  EJECUTOR  │ ARCHIVADOR │            │  │
│  │  │  (proceso) │ (proceso)  │ (proceso)  │            │  │
│  │  │   ┌─────┐  │  ┌─────┐   │  ┌─────┐   │            │  │
│  │  │   │NIVEL│  │  │NIVEL│   │  │NIVEL│   │            │  │
│  │  │   │  3  │  │  │  3  │   │  │  3  │   │            │  │
│  │  │   │Sub- │  │  │Sub- │   │  │Sub- │   │            │  │
│  │  │   │agent│  │  │agent│   │  │agent│   │            │  │
│  │  │   └─────┘  │  └─────┘   │  └─────┘   │            │  │
│  │  └────────────┴────────────┴────────────┘            │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘

CADA NIVEL:
- Tiene memoria INDIVIDUAL de nivel
- Tiene memoria COLECTIVA de nivel
- Tiene RAG INDIVIDUAL de nivel
- Tiene RAG COLECTIVO de nivel
- Expone interfaz UNIFICADA al nivel superior
```

### Niveles de la Jerarquía

| Nivel | Código | Composición | Descripción |
|-------|--------|-------------|-------------|
| **L0** | SUB | Trabajadores efímeros | Sin memoria, mueren tras tarea |
| **L1** | ESP | Agente individual | Proceso Node.js base |
| **L2** | CONCILIUM | 3 procesos (tri-agente) | Bloque de construcción |
| **L3** | DOMINIO | Concilios + Catedrático | Área funcional |
| **L4** | SISTEMA | Múltiples dominios | Orquestador global |

---

## Los Tres Roles

### 1. DIRECTOR (Orquestador)

```
┌─────────────────────────────────────┐
│           DIRECTOR                   │
│                                      │
│  Modelo: claude-opus-4-6             │
│  Puerto: 8081                        │
│  Entry Point: SÍ                     │
│                                      │
│  ════════════════════════════════    │
│                                      │
│  FUNCIONES:                          │
│  • Recibe solicitudes del usuario    │
│  • Analiza y planifica tareas        │
│  • Delega al Ejecutor                │
│  • Coordina el concilio              │
│  • Recibe validación del Archivador  │
│  • Entrega respuesta final           │
│                                      │
│  CARACTERÍSTICAS:                    │
│  • Visión estratégica                │
│  • Toma de decisiones                │
│  • Comunicación con usuario          │
│                                      │
│  COMUNICACIÓN:                       │
│  • Redis publish: concilio:ejecutor  │
│  • Redis publish: concilio:archivador│
│                                      │
└─────────────────────────────────────┘
```

### 2. EJECUTOR (Productor)

```
┌─────────────────────────────────────┐
│           EJECUTOR                   │
│                                      │
│  Modelo: claude-sonnet-4.6           │
│  Puerto: 8082                        │
│  Entry Point: NO                     │
│                                      │
│  ════════════════════════════════    │
│                                      │
│  FUNCIONES:                          │
│  • Recibe tareas delegadas           │
│  • Ejecuta trabajo técnico           │
│  • Genera código, documentos, etc.   │
│  • Realiza cálculos y análisis       │
│  • Entrega resultados al Director    │
│                                      │
│  CARACTERÍSTICAS:                    │
│  • Precisión técnica                 │
│  • Eficiencia en ejecución           │
│  • Calidad de output                 │
│                                      │
│  HERRAMIENTAS:                       │
│  • bash, read, write, edit          │
│  • browser, process                 │
│                                      │
│  COMUNICACIÓN:                       │
│  • Redis publish: concilio:director  │
│                                      │
└─────────────────────────────────────┘
```

### 3. ARCHIVADOR (Validador)

```
┌─────────────────────────────────────┐
│          ARCHIVADOR                  │
│                                      │
│  Modelo: claude-haiku-4.5            │
│  Puerto: 8083                        │
│  Entry Point: NO                     │
│                                      │
│  ════════════════════════════════    │
│                                      │
│  FUNCIONES:                          │
│  • Recibe artefactos para validar    │
│  • Verifica calidad y corrección     │
│  • Documenta decisiones              │
│  • Actualiza memoria del sistema     │
│  • Entrega validación al Director    │
│                                      │
│  CARACTERÍSTICAS:                    │
│  • Rigor en revisión                 │
│  • Memoria persistente               │
│  • Documentación exhaustiva          │
│                                      │
│  MEMORIA (Individual + Compartida):  │
│  • decisiones.md                     │
│  • patrones.md                       │
│  • errores.md                        │
│  • mejores-practicas.md              │
│                                      │
│  COMUNICACIÓN:                       │
│  • Redis publish: concilio:director  │
│                                      │
└─────────────────────────────────────┘
```

---

## Flujo de Decisiones en el Concilio

### Flujo Completo

```
                    ┌──────────────────┐
                    │    USUARIO       │
                    │  (Telegram/      │
                    │   Discord)       │
                    └────────┬─────────┘
                             │
                             │ 1. Solicitud
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                         DIRECTOR                             │
│                         (Puerto 8081)                        │
│                                                              │
│  2. Analizar solicitud                                       │
│  3. Crear plan de trabajo                                    │
│  4. Identificar tareas a delegar                             │
│                                                              │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ 5. Delegar tarea
                           │    Redis publish: concilio:ejecutor
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                         EJECUTOR                             │
│                         (Puerto 8082)                        │
│                                                              │
│  6. Recibir tarea (Redis subscribe)                         │
│  7. Ejecutar trabajo                                         │
│  8. Generar artefacto (código, documento, etc.)              │
│                                                              │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ 9. Entregar resultado
                           │    Redis publish: concilio:director
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                         DIRECTOR                             │
│                                                              │
│  10. Recibir resultado                                       │
│  11. Solicitar validación                                    │
│                                                              │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ 12. Solicitar validación
                           │     Redis publish: concilio:archivador
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                        ARCHIVADOR                            │
│                         (Puerto 8083)                        │
│                                                              │
│  13. Recibir artefacto (Redis subscribe)                    │
│  14. Validar calidad                                         │
│  15. Verificar contra requisitos                             │
│  16. Documentar decisión                                     │
│  17. Actualizar memoria                                      │
│                                                              │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ 18. Entregar validación
                           │     Redis publish: concilio:director
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                         DIRECTOR                             │
│                                                              │
│  19. Recibir validación                                      │
│  20. Componer respuesta final                                │
│  21. Entregar al usuario                                     │
│                                                              │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ 22. Respuesta validada
                           ▼
                    ┌──────────────────┐
                    │    USUARIO       │
                    └──────────────────┘
```

### Estados de Validación

| Estado | Significado | Acción del Director |
|--------|-------------|---------------------|
| **APROBADO** | Artefacto correcto y completo | Entregar al usuario |
| **RECHAZADO** | Artefacto con errores críticos | Re-delegar al Ejecutor con correcciones |
| **MODIFICACIONES_REQUERIDAS** | Artefacto funcional pero mejorable | Aplicar mejoras y entregar |

---

## Memoria del Concilio

### Niveles de Memoria

```
┌─────────────────────────────────────────────────────────────┐
│                    MEMORIA INDIVIDUAL                        │
│                    (Por cada proceso)                        │
│                                                              │
│  Cada agente tiene SU memoria:                               │
│  • workspace/memoria/                                        │
│  • Base vectorial individual (LanceDB)                       │
│  • Conversaciones privadas                                   │
│  • Aprendizajes personales                                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    MEMORIA DEL CONCILIO                      │
│                    (Compartida - Nivel L2)                   │
│                                                              │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │  decisiones.md  │  │   patrones.md   │                   │
│  │                 │  │                 │                   │
│  │ • Qué se decidió│  │ • Qué funciona  │                   │
│  │ • Por qué       │  │ • Cómo repetir  │                   │
│  │ • Consecuencias │  │ • Anti-patrones │                   │
│  └─────────────────┘  └─────────────────┘                   │
│                                                              │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │   errores.md    │  │mejores-practicas│                   │
│  │                 │  │                 │                   │
│  │ • Qué falló     │  │ • Lecciones     │                   │
│  │ • Por qué       │  │ • Optimizaciones│                   │
│  │ • Cómo evitar   │  │ • Tips          │                   │
│  └─────────────────┘  └─────────────────┘                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    RAG COMPARTIDO                            │
│                    (Conocimiento Validado)                   │
│                                                              │
│  Solo conocimiento APROBADO por el Archivador:               │
│  • Fragmentos con validation_status: "validated"             │
│  • Búsqueda semántica compartida                             │
│  • Promoción desde pending → validated                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Filtro de Validación

**Regla de Oro**: Solo las decisiones aprobadas por el Archivador se guardan en memoria compartida.

```
Artefacto validado → ARCHIVADOR
                          │
                          ▼
                 ┌───────────────┐
                 ¿APROBADO?      │
                 └───────┬───────┘
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
           SÍ                     NO
              │                     │
              ▼                     ▼
    ┌─────────────────┐    ┌─────────────────┐
    │ Promover a      │    │ Registrar en    │
    │ RAG Compartido  │    │ errores.md      │
    │                 │    │                 │
    │ validation_     │    │ • Qué falló     │
    │ status:         │    │ • Por qué       │
    │ "validated"     │    │ • Cómo evitar   │
    └─────────────────┘    └─────────────────┘
```

---

## Communication Ring (Redis Pub/Sub)

### Arquitectura del Ring

```
┌─────────────────────────────────────────────────────────────────┐
│                    COMMUNICATION RING                            │
│                    (Redis Pub/Sub)                               │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                  CANALES                                 │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │    │
│  │  │ concilio:    │  │ concilio:    │  │ concilio:    │  │    │
│  │  │ director     │  │ ejecutor     │  │ archivador   │  │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │    │
│  │  ┌──────────────────────────────────────────────────┐   │    │
│  │  │ concilio:broadcast (todos los agentes)           │   │    │
│  │  └──────────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   DIRECTOR      │ │   EJECUTOR      │ │   ARCHIVADOR    │
│                 │ │                 │ │                 │
│  Subscribe:     │ │  Subscribe:     │ │  Subscribe:     │
│  • director     │ │  • ejecutor     │ │  • archivador   │
│  • broadcast    │ │  • broadcast    │ │  • broadcast    │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

### Tipos de Mensajes

| Tipo | Descripción | Ejemplo |
|------|-------------|---------|
| **task** | Delegar trabajo | Director → Ejecutor |
| **result** | Resultado de trabajo | Ejecutor → Director |
| **validation** | Resultado de validación | Archivador → Director |
| **query** | Consulta entre agentes | Cualquier agente |
| **broadcast** | A todos los agentes | Estado del sistema |

---

## RAG Jerárquico

### Estructura

```
┌─────────────────────────────────────────────────────────────┐
│                    RAG JERÁRQUICO                            │
│                                                              │
│  NIVEL L2 (Concilio):                                        │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  RAG Compartido del Concilio (LanceDB)               │    │
│  │  • Conocimiento validado por los 3 agentes           │    │
│  │  • Tablas: validated, pending, rejected              │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  NIVEL L1 (Agente Individual):                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ RAG Director│  │ RAG Ejecutor│  │RAG Archivador│         │
│  │ (individual)│  │ (individual)│  │ (individual) │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Flujo de Búsqueda

```typescript
async function searchKnowledge(query: string, agent: Agent) {
  const results = [];

  // 1. Buscar en RAG individual (más relevante)
  const individual = await agent.individualRag.search(query);
  results.push(...individual);

  // 2. Buscar en RAG compartido del concilio
  if (agent.collectiveRag) {
    const shared = await agent.collectiveRag.search(query);
    results.push(...shared);
  }

  // 3. Re-rankear por relevancia
  return rerankResults(results, query);
}
```

---

## Learning Engine

### Niveles de Encapsulación

```
┌─────────────────────────────────────────────────────────────┐
│  NIVEL 4: SABIDURÍA ENCAPSULADA                              │
│  Principios y patrones reutilizables por agentes superiores  │
│  → Disponible para todos los niveles superiores              │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ Validación score ≥ 0.8
┌─────────────────────────────────────────────────────────────┐
│  NIVEL 3: CONOCIMIENTO VALIDADO                              │
│  Lecciones validadas por el Archivador                       │
│  → Promovido desde pending                                   │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ Procesamiento LLM
┌─────────────────────────────────────────────────────────────┐
│  NIVEL 2: LECCIÓN PROCESADA                                  │
│  Extracción de principio general                             │
│  → ¿Qué funcionó? ¿Qué falló? ¿Qué principio?                │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ Submit
┌─────────────────────────────────────────────────────────────┐
│  NIVEL 1: EXPERIENCIA CRUDA                                  │
│  Request + Response + Contribuciones                         │
│  → Desde el concilio                                          │
└─────────────────────────────────────────────────────────────┘
```

---

## El Concilio como Bloque de Construcción

### Unidad Especialista = 1 Concilio

```
┌─────────────────────────────────────────────────────────────┐
│              UNIDAD ESPECIALISTA (Ej: ESP-DES)              │
│                                                              │
│   Este es el "ladrillo" o "bloque de hormigón"              │
│   que se replica para cada dominio                          │
│                                                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │              CONCILIO TRI-AGENTE                     │   │
│   │         (3 procesos + comunicación)                  │   │
│   │                                                      │   │
│   │   DIRECTOR + EJECUTOR + ARCHIVADOR                   │   │
│   │                                                      │   │
│   │   + Memoria específica del dominio                   │   │
│   │   + Skills específicas del dominio                   │   │
│   │   + Conocimiento específico del dominio              │   │
│   │                                                      │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Replicación para Múltiples Dominios

```
ESP-DES (Desarrollo)
├── director-des (puerto 8081)
├── ejecutor-des (puerto 8082)
├── archivador-des (puerto 8083)
└── memoria/ (específica de desarrollo)

ESP-INF (Infraestructura)
├── director-inf (puerto 8091)
├── ejecutor-inf (puerto 8092)
├── archivador-inf (puerto 8093)
└── memoria/ (específica de infra)
```

### Catedráticos = 1 Proceso Simple

Los Catedráticos NO usan patrón tri-agente:

```
JEF-ING (Catedrático de Ingeniería)
├── 1 proceso (no concilio)
├── Supervisa a ESP-DES e ESP-INF
├── Toma decisiones estratégicas
└── Coordina entre especialistas de su área
```

### Jerarquía Completa

```
SIS (1 proceso - Orquestador global)
│
├── JEF-CON (1 proceso)
│   └── ESP-ACA (3 procesos)
│
├── JEF-ING (1 proceso)
│   ├── ESP-DES (3 procesos)
│   └── ESP-INF (3 procesos)
│
├── JEF-OPE (1 proceso)
│   └── ESP-HOS (3 procesos)
│
├── JEF-RHU (1 proceso)
│   └── Fábrica de Agentes
│
├── JEF-REX (1 proceso)
│   ├── ESP-CRI (3 procesos)
│   └── ESP-FIN (3 procesos)
│
└── JEF-COM (1 proceso)
    └── ESP-IDI (3 procesos)
```

---

## Beneficios del Concilio Tri-Agente

### 1. Estabilidad

- **Redundancia**: 3 agentes pueden compensar fallos
- **Validación cruzada**: Errores detectados antes de llegar al usuario
- **Consistencia**: Memoria actúa como ancla de conocimiento

### 2. Calidad

- **Triple revisión**: Cada output pasa por 3 perspectivas
- **Especialización**: Cada rol optimizado para su función
- **Filtro de memoria**: Solo conocimiento validado persiste

### 3. Escalabilidad Fractal

- **Patrón replicable**: Mismo bloque para todos los dominios
- **Interfaz unificada**: Cada nivel se ve como 1 entidad desde arriba
- **Memoria jerárquica**: Individual → Colectiva → Heredada

### 4. Auditabilidad

- **Rastro completo**: Cada decisión tiene historial
- **Responsabilidad clara**: Se sabe quién hizo qué
- **Memoria consultable**: Registro de todo conocimiento

---

## Checklist de Verificación

```
□ Infraestructura:
  □ Redis corriendo
  □ Node.js 22+ instalado
  □ Estructura de directorios creada

□ Procesos:
  □ Director corriendo en puerto 8081
  □ Ejecutor corriendo en puerto 8082
  □ Archivador corriendo en puerto 8083

□ Comunicación:
  □ Redis pub/sub funcional
  □ Director puede enviar a Ejecutor
  □ Director puede enviar a Archivador
  □ Ambos pueden responder a Director

□ Memoria:
  □ LanceDB configurado por agente
  □ RAG compartido accesible
  □ Archivos de memoria creados

□ Flujo completo probado:
  □ Enviar solicitud → Director
  □ Director delega → Ejecutor
  □ Ejecutor produce → resultado
  □ Director solicita → validación
  □ Archivador valida → memoria actualizada
  □ Director entrega → usuario
```

---

**Documento:** El Concilio Tri-Agente - Patrón Arquitectónico
**Ubicación:** `docs/INSTALACION-PERSONAL/10-PATRON-TRI-AGENTE.md`
**Versión:** 3.0 (Arquitectura Custom - Fastify + Redis)
**Fecha:** 2026-03-10
