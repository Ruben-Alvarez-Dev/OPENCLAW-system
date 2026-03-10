# Arquitectura Maestra - OPENCLAW Sistema Multi-Agente

**ID:** DOC-SIS-ARQ-001
**Versión:** 2.1.0
**Fecha:** 2026-03-09
**Estado:** Arquitectura Definitiva
**Basado en:** Análisis completo de requisitos y decisiones de diseño

---

## Resumen Ejecutivo

OPENCLAW es un **sistema multi-agente jerárquico** diseñado para emular organizaciones humanas estructuradas. Combina orquestación, especialización por dominios y unidades de verificación tri-agentes para producir outputs estables, validados y auditables a lo largo del tiempo.

### Objetivos Principales

1. **Estabilidad a largo plazo** - Sistema robusto que no degrada con el tiempo
2. **Procesos auto-mejorables** - Aprendizaje acumulativo de lecciones
3. **Conocimiento estructurado** - Fuentes verificadas, no improvisación
4. **Separación de responsabilidades** - Razonamiento, ejecución y validación separados
5. **Dominios expansibles** - Creación dinámica de nuevos especialistas

---

## 1. Jerarquía del Sistema (4 Niveles)

### Visión General

```
┌─────────────────────────────────────────────────────────────────┐
│                     NIVEL 0 - ORCHESTRATOR                      │
│                     (Unidad Tri-Agente)                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │  Director   │  │  Ejecutor   │  │ Archivador  │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│  Entrada usuario, coordinación global, routing de dominios      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     NIVEL 1 - DOMAIN CHIEFS                     │
│                     (Agentes Simples)                           │
│  ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐   │
│  │JEF-CON│ │JEF-ING│ │JEF-OPE│ │JEF-RHU│ │JEF-REX│ │JEF-COM│   │
│  └───────┘ └───────┘ └───────┘ └───────┘ └───────┘ └───────┘   │
│  Decisiones estratégicas, coordinación de dominio               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   NIVEL 2 - SPECIALIST UNITS                    │
│                   (Unidades Tri-Agente)                         │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  DEV Unit        │  Director + Ejecutor + Archivador     │  │
│  │  Infra Unit      │  Director + Ejecutor + Archivador     │  │
│  │  Research Unit   │  Director + Ejecutor + Archivador     │  │
│  │  Gastronomy Unit │  Director + Ejecutor + Archivador     │  │
│  │  Sports Unit     │  Director + Ejecutor + Archivador     │  │
│  └───────────────────────────────────────────────────────────┘  │
│  Ejecución con validación interna                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   NIVEL 3 - EPHEMERAL SUBAGENTS                 │
│                   (Workers Temporales)                          │
│  Workers sin memoria que mueren al completar tarea              │
└─────────────────────────────────────────────────────────────────┘
```

### Justificación de la Estructura

| Nivel | Tipo | Razón |
|-------|------|-------|
| 0 | Tri-agente | Robustez central para coordinación crítica |
| 1 | Agente simple | Eficiencia para decisiones estratégicas |
| 2 | Tri-agente | Validación + calidad de ejecución |
| 3 | Workers simples | Escalabilidad para tareas paralelas |

### ¿Por qué no todo tri-agente?

- **Demasiados LLMs** → Sistema lento, costos altos
- **Todo agentes simples** → Menos robustez, errores no detectados
- **Esta estructura** → Equilibrio entre control, robustez y eficiencia

---

## 2. Estructura Tri-Agente (Triunvirato)

### Componentes

```
Unidad Especialista (Tri-Agente)
│
├── Director (El Planificador)
│   ├── Planificación y estrategia
│   ├── Delegación de tareas
│   ├── Consolidación de resultados
│   └── Control de calidad final
│
├── Ejecutor (El Implementador)
│   ├── Ejecución de comandos
│   ├── Cálculos y generación
│   ├── Manipulación de archivos
│   └── Interacción con APIs
│
└── Archivador (El Persistente)
    ├── Observación silenciosa
    ├── Validación de coherencia
    ├── Persistencia en Vault
    └── Indexación semántica (RAG)
```

### Flujo de Responsabilidad

```
Request → Director (planifica)
              │
              ▼
         Ejecutor (ejecuta)
              │
              ▼
         Archivador (valida)
              │
              ▼
         Response (si pasa validación)
```

### Permisos por Rol

| Capacidad | Director | Ejecutor | Archivador |
|-----------|----------|----------|------------|
| Ejecutar shell | ❌ | ✅ (validado) | ❌ |
| Ejecutar Python | ❌ | ✅ (sandbox) | ❌ |
| Leer archivos | ❌ | ✅ (sandbox) | ✅ (todos) |
| Escribir archivos | ❌ | ✅ (sandbox) | ✅ (Vault) |
| Acceso red externa | ❌ | ✅ (HTTP) | ❌ |
| Memoria persistente | ❌ | ❌ | ✅ |
| Generar embeddings | ❌ | ❌ | ✅ |
| Validar comandos | ✅ | ❌ | ❌ |
| Consolidar resultados | ✅ | ❌ | ❌ |

---

## 3. Interfaz de Usuario: Comandos por Namespace

### Modelo de Interacción

El usuario **NO** interactúa directamente con agentes internos. La interacción ocurre a través de **namespaces de dominio**:

### Namespaces Disponibles

```
/dev          → Desarrollo, programación, arquitectura software
/infra        → Infraestructura, DevOps, servidores, networking
/crypto       → Criptomonedas, blockchain, DeFi
/inversiones  → Inversión, finanzas, trading
/hosteleria   → Hostelería, gastronomía, F&B
/f&b          → Food & Beverage (alias de hosteleria)
/fitness      → Deportes, entrenamiento, salud
/oposiciones  → Preparación de exámenes, académico
/english      → Aprendizaje de idiomas
```

### Ejemplos de Uso

**Comando explícito:**
```
/dev diseñar arquitectura de cluster distribuido
/infra configurar VPS Ubuntu con Docker
/hosteleria diseñar carta de vinos para restaurante italiano
```

**Lenguaje natural implícito:**
```
"Diseñar una infraestructura distribuida"
→ Router detecta: /infra

"Crear plan de entrenamiento para maratón"
→ Router detecta: /fitness

"Analizar documento de ingeniería automotriz"
→ Router detecta: /dev
```

### Arquitectura de Interacción

```
┌─────────────────────────────────────────────────────────────┐
│                     USUARIO                                 │
│         "/dev diseñar arquitectura cluster"                │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   COMMAND ROUTER                            │
│  1. Detectar namespace (/dev)                              │
│  2. Si no hay namespace → clasificación semántica          │
│  3. Ruta a dominio apropiado                               │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   DOMAIN CHIEF (CEngO)                      │
│  1. Analiza petición                                       │
│  2. Decide qué especialista usar                           │
│  3. Coordina unidad                                        │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                DEV SPECIALIST UNIT (tri-agent)              │
│  Director → Ejecutor → Archivador → Resultado validado     │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                     RESPUESTA AL USUARIO                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Los Seis Catedráticos (Jefes de Dominio)

### Nivel JEF - Agentes de Coordinación

| Catedrático | Código | ID | Dominio |
|-------------|--------|-----|---------|
| **JEF-CON** | CON | JEF-CON-UNI-001 | Conocimiento, documentación, investigación |
| **JEF-ING** | ING | JEF-ING-UNI-001 | Ingeniería, arquitectura, calidad técnica |
| **JEF-OPE** | OPE | JEF-OPE-UNI-001 | Operaciones, procesos, automatización |
| **JEF-RHU** | RHU | JEF-RHU-UNI-001 | RRHH, talento, **Fábrica de Agentes** |
| **JEF-REX** | REX | JEF-REX-UNI-001 | Relaciones externas, estrategia |
| **JEF-COM** | COM | JEF-COM-UNI-001 | Comunicaciones internas |

### Responsabilidades Clave

**Cada Catedrático es responsable del resultado final antes de mostrar al usuario.**

Esto significa:
- ✅ Delega trabajo a unidades especializadas
- ✅ Revisa el resultado
- ✅ Valida antes de entregar
- ❌ NO delega la aprobación final

### ¿Por qué son agentes simples (no tri-agentes)?

- Son decisiones estratégicas, no ejecución técnica
- Eficiencia: no necesitan validación interna para coordinación
- La validación ocurre en las unidades especializadas (Nivel 2)

### Soporte Tri-Agente Interno

Cuando un Catedrático necesita robustez adicional para una decisión compleja:

```
Catedrático (interfaz simple)
│
├── Director interno (estrategia)
├── Ejecutor interno (análisis)
└── Archivador interno (validación)
```

El usuario siempre percibe un solo agente, pero internamente puede activar su tri-unidad.

---

## 5. Domain Router

### Funciones

1. **Detección de namespace explícito**: `/dev`, `/infra`, `/hosteleria`
2. **Clasificación semántica implícita**: Cuando no hay namespace
3. **Creación de dominios**: Si el dominio no existe, escala al Fábrica de Agentes

### Proceso de Routing

```
Input del usuario
       │
       ▼
┌──────────────────┐
│ ¿Tiene namespace?│
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
   SÍ        NO
    │         │
    ▼         ▼
┌───────┐ ┌────────────────────┐
│Extraer│ │ Clasificación      │
│/tag   │ │ semántica          │
└───┬───┘ └─────────┬──────────┘
    │               │
    └───────┬───────┘
            │
            ▼
    ┌───────────────┐
    │ ¿Dominio      │
    │ existe?       │
    └───────┬───────┘
            │
       ┌────┴────┐
       │         │
      SÍ        NO
       │         │
       ▼         ▼
┌──────────┐ ┌─────────────────┐
│Route a   │ │ Fábrica de Agentes   │
│Chief     │ │ crea dominio    │
└──────────┘ └─────────────────┘
```

### Ejemplo de Routing Implícito

```
Input: "Diseñar un sistema de riego automatizado"

Análisis semántico:
- engineering ✓
- agriculture ✓
- automation ✓

Dominio elegido: ingeniería → /dev
Especialista: ingeniería agrícola
```

---

## 6. Fábrica de Agentes (Sistema de RRHH)

### Ubicación

Bajo el Catedrático **JEF-RHU** (Jefe de Recursos Humanos)

### Función

Crear dinámicamente nuevos dominios y unidades especializadas cuando el sistema no tiene expertise.

### Proceso de Creación

```
1. Router detecta que dominio no existe
          │
          ▼
2. Fábrica de Agentes selecciona template
          │
          ▼
3. Template + fuente de conocimiento + configuración
          │
          ▼
4. Nueva unidad especialista creada
          │
          ▼
5. Dominio registrado en Agent Registry
```

### Estructura de Template

```
plantilla_especialista/
├── director_prompt     # System prompt del Director
├── ejecutor_prompt     # System prompt del Ejecutor
├── archivador_prompt   # System prompt del Archivador
├── herramientas        # Herramientas disponibles
├── habilidades         # Skills específicas
└── config_memoria      # Configuración de memoria
```

### Ejemplos de Dominios Creados Dinámicamente

```
/floristeria     → Unidad de diseño floral
/autoengine      → Unidad de ingeniería automotriz
/cuantica        → Unidad de física cuántica
/albanileria     → Unidad de construcción
```

### Biblioteca de Agentes

```
agent_library/
├── domains/              # Dominios creados
│   ├── floristry/
│   ├── quantum_physics/
│   └── automotive/
├── specialist_units/     # Unidades especializadas
└── templates/            # Templates base
```

Los dominios creados **no se ejecutan constantemente**. Solo se cargan cuando se necesitan.

---

## 7. Knowledge Engine (5 Capas)

### Arquitectura de Conocimiento

```
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 1: Foundation Model Knowledge                             │
│  ────────────────────────────────────────────────────────────── │
│  Conocimiento general del modelo LLM: matemáticas, lógica,      │
│  física básica, programación, economía general                  │
│                                                                 │
│  Uso: Razonamiento, síntesis, inferencia, planificación        │
│  Limitación: Puede estar desactualizado, puede contener errores │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 2: Local Academic Libraries                               │
│  ────────────────────────────────────────────────────────────── │
│  Manuales universitarios, libros de ingeniería, textos de       │
│  medicina, manuales técnicos, normativas oficiales              │
│                                                                 │
│  Estructura:                                                    │
│  knowledge/                                                     │
│  ├── engineering/                                               │
│  │   ├── mechanical/                                            │
│  │   ├── electrical/                                            │
│  │   └── software/                                              │
│  ├── finance/                                                   │
│  ├── gastronomy/                                                │
│  └── sports/                                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 3: Technical Standards & Norms                            │
│  ────────────────────────────────────────────────────────────── │
│  ISO, IEEE, normativas nacionales, manuales industriales,       │
│  protocolos técnicos                                            │
│                                                                 │
│  Uso: Validación de resultados contra estándares                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 4: System Memory (Lessons Learned)                        │
│  ────────────────────────────────────────────────────────────── │
│  Decisiones técnicas tomadas, soluciones probadas,              │
│  errores detectados, procedimientos optimizados                 │
│                                                                 │
│  Estructura:                                                    │
│  system_memory/                                                 │
│  ├── architecture_decisions/                                    │
│  ├── engineering_solutions/                                     │
│  ├── workflows/                                                 │
│  └── lessons_learned/                                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 5: External Research Sources                              │
│  ────────────────────────────────────────────────────────────── │
│  Papers académicos, repositorios científicos, documentación     │
│  técnica oficial, bases de datos científicas                    │
│                                                                 │
│  Fuentes fiables: arXiv, PubMed, IEEE, ACM, MIT OCW            │
│  EVITAR: blogs, opiniones, foros, contenido sin fuente          │
└─────────────────────────────────────────────────────────────────┘
```

### Prioridad de Consulta

```
1. Memoria del sistema (Capa 4)
2. Fuentes personales (si existen)
3. Bibliotecas académicas (Capa 2)
4. Estándares técnicos (Capa 3)
5. Investigación externa (Capa 5)
```

### Fuentes de Conocimiento Personal

El sistema soporta ingesta de documentación proporcionada por el usuario:

```
knowledge_sources/
├── personal/
│   ├── dev/              # Notas de ingeniería, docs de arquitectura
│   ├── infra/            # Configs de servidor, guías de deployment
│   ├── hosteleria/       # Procedimientos F&B, recetas, estándares
│   └── deportes/         # Programas de entrenamiento, técnicas
├── academic/
└── standards/
```

### Flujo de Consulta

```
Pregunta
    │
    ▼
┌──────────────────┐
│ Buscar en        │
│ memoria interna  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Buscar en        │
│ fuentes persona. │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Buscar en        │
│ bibliotecas acad.│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Consultar        │
│ estándares       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Investigación    │
│ externa si falta │
└────────┬─────────┘
         │
         ▼
    Síntesis final
```

---

## 8. Memory Architecture (4 Tipos)

### Tipos de Memoria

```
┌─────────────────────────────────────────────────────────────────┐
│  MEMORIA DE AGENTE                                             │
│  ────────────────────────────────────────────────────────────── │
│  Específica de cada especialista individual                    │
│  Almacenamiento: Vector DB por agente                          │
│                                                                 │
│  Ejemplo: Memoria del Ejecutor de DEV Unit                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  MEMORIA DE UNIDAD                                             │
│  ────────────────────────────────────────────────────────────── │
│  Compartida dentro de la unidad tri-agente                     │
│  Almacenamiento: Storage a nivel de unidad                     │
│                                                                 │
│  Ejemplo: Memoria compartida de DEV Unit                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  MEMORIA DE DOMINIO                                            │
│  ────────────────────────────────────────────────────────────── │
│  Compartida entre todos los especialistas de un dominio        │
│  Almacenamiento: Knowledge base del dominio                    │
│                                                                 │
│  Ejemplo: Memoria de todo el dominio /dev                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  MEMORIA GLOBAL                                                │
│  ────────────────────────────────────────────────────────────── │
│  Conocimiento de todo el sistema                               │
│  Almacenamiento: Central knowledge library                     │
│                                                                 │
│  Ejemplo: Decisiones arquitectónicas globales, lecciones       │
└─────────────────────────────────────────────────────────────────┘
```

### Tabla de Memorias

| Tipo | Scope | Contenido | Storage |
|------|-------|-----------|---------|
| Agente | Individual | Contexto personal del agente | Vector DB individual |
| Unidad | Tri-agente | Colaboración entre Director/Ejecutor/Archivador | Unit-level storage |
| Dominio | Todos en /dev, /infra, etc. | Conocimiento del dominio | Domain KB |
| Global | Sistema completo | Lecciones globales | Central library |

---

## 9. Modelo de Responsabilidad

### Regla Principal

> **El dominio que responde al usuario es responsable del resultado.**

### Validación Multicapa

```
1. Specialist Archivist (Nivel 2)
   └── Valida coherencia interna de la unidad

2. Domain Chief (Nivel 1)
   └── Valida calidad antes de entregar

3. System Policies
   └── Valida cumplimiento de normas globales
```

### Mecanismos de Seguridad

- **Command approval**: Validación de comandos antes de ejecución
- **Sandbox execution**: Ejecución aislada en Docker
- **Source verification**: Verificación de fuentes de conocimiento
- **Consistency checks**: Verificación de coherencia de resultados

---

## 10. Middleware

### Componentes de Infraestructura

El middleware NO debe ser agentes LLM. Debe ser software clásico:

```
middleware/
├── memory_layer/         # Capa de memoria
├── vector_search/        # Búsqueda vectorial
├── permissions/          # Sistema de permisos
├── skill_registry/       # Registro de skills
├── agent_registry/       # Registro de agentes
└── communication_bus/    # Bus de comunicación
```

### Tecnologías Base

| Componente | Tecnología |
|------------|------------|
| Database | PostgreSQL |
| Vector DB | SQLite-vec / LanceDB |
| Cache | Redis |
| Message Queue | RabbitMQ / NATS |
| Filesystem | Structured directories |

---

## 11. Flujo de Ejecución Completo

### Ejemplo: `/dev diseñar arquitectura de cluster`

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. USUARIO                                                      │
│    Input: "/dev diseñar arquitectura de cluster distribuido"   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. COMMAND ROUTER                                               │
│    - Detecta namespace: /dev                                   │
│    - Clasifica: arquitectura software, distribuido             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. ORCHESTRATOR (Level 0)                                       │
│    - Recibe request                                             │
│    - Route a JEF-ING (Jefe de Ingeniería)                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. JEF-ING (Level 1)                                            │
│    - Analiza petición                                           │
│    - Decide: usar DEV Specialist Unit                          │
│    - Delega                                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. DEV SPECIALIST UNIT (Level 2 - Tri-agent)                   │
│                                                                 │
│    Director:                                                    │
│    - Planifica enfoque                                          │
│    - Consulta biblioteca ingeniería software                   │
│    - Consulta estándares arquitectura                          │
│                                                                 │
│    Ejecutor:                                                    │
│    - Genera diseño arquitectónico                              │
│    - Crea diagramas                                             │
│    - Documenta decisiones                                       │
│                                                                 │
│    Archivador:                                                  │
│    - Valida coherencia del diseño                              │
│    - Indexa en Vault                                            │
│    - Actualiza memoria de unidad                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. JEF-ING (Validación Final)                                   │
│    - Revisa resultado                                           │
│    - Valida calidad                                             │
│    - Aprueba para entrega                                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. RESPUESTA AL USUARIO                                         │
│    - Diseño arquitectónico validado                            │
│    - Documentación incluida                                     │
│    - Guardado en memoria del sistema                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 12. Reglas de Diseño

### Lo que debe hacer el sistema

- ✅ Hablar con dominios via namespaces
- ✅ Routing automático por semántica
- ✅ Crear nuevos dominios dinámicamente
- ✅ Validar outputs antes de entregar
- ✅ Consultar fuentes verificadas
- ✅ Acumular conocimiento en memoria

### Lo que NO debe hacer el sistema

- ❌ Generar conocimiento nuevo sin fuentes
- ❌ Confiar en blogs o especulaciones
- ❌ Delegar responsabilidad final
- ❌ Crear agentes LLM innecesarios
- ❌ Operar sin middleware de soporte

### Principio Fundamental

> **IA para pensar, software para gestionar**

---

## 13. Validación Multicapa (5 Capas)

### Visión General

El sistema implementa 5 capas de validación para garantizar calidad, coherencia y seguridad:

```
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 5: HUMAN APPROVAL                                         │
│  Aprobación humana para operaciones críticas y destructivas     │
└─────────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 4: CROSS-UNIT VALIDATION                                  │
│  Segunda opinión de otra unidad especialista                    │
└─────────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 3: DOMAIN CHIEF REVIEW                                    │
│  Revisión por Catedrático antes de entrega                      │
└─────────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 2: AI-IN-THE-LOOP                                         │
│  Supervisión automática por IA en puntos críticos               │
└─────────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 1: TRI-AGENT VALIDATION (Interna)                         │
│  Validación dentro de la unidad tri-agente                      │
└─────────────────────────────────────────────────────────────────┘
```

### Capa 2: AI-in-the-Loop

Supervisión automática por IA en puntos críticos:

| Gate | Función | Acción si Falla |
|------|---------|-----------------|
| **Input Classification** | Detectar malicia, clasificar complejidad | Bloquear + escalar |
| **Execution Monitoring** | Detectar anomalías en tiempo real | Pausar + notificar |
| **Output Validation** | Verificar coherencia, hechos, calidad | Flag + revisar |
| **Memory Consistency** | Verificar no contradicciones | Rechazar escritura |

**Ver documento completo:** [08-FLUJOS/02-validacion.md](../08-FLUJOS/02-validacion.md)

### Capa 5: Human-in-the-Loop

Aprobación humana obligatoria para:

| Categoría | Operaciones |
|-----------|-------------|
| **Destructivas** | rm, drop, delete, truncate |
| **Producción** | deployments, config changes |
| **Financieras** | operaciones > threshold |
| **Sensibles** | acceso a datos personales |
| **Sistema** | modificación de políticas |

**Capacidades Humanas:**
- Override cualquier decisión del sistema
- Forzar aprobación de operaciones bloqueadas
- Modificar reglas de validación
- Añadir excepciones permanentes

---

## 14. Sistema de Mensajería Auditable

### Principios

1. **Todo mensaje es registrado** - Append-only audit log
2. **Cadena de integridad** - Hash chain inmutable
3. **Trazabilidad completa** - Trace ID propagation
4. **Chain of custody** - Firma digital de cada mensaje

### Estructura del Mensaje

```typescript
interface Message {
  id: string;                    // UUID único
  timestamp: number;             // Unix timestamp
  source: MessageEndpoint;       // Origen
  target: MessageEndpoint;       // Destino
  type: MessageType;             // Tipo de mensaje
  payload: unknown;              // Contenido
  parent_id: string | null;      // Referencia al mensaje padre
  chain_hash: string;            // Hash de integridad
  signature: string;             // Firma digital
  trace_id: string;              // ID de trazabilidad
}
```

### Cadena de Integridad

```
Message N
│
├── previous_hash: hash(Message N-1)
├── content_hash: hash(payload)
├── chain_hash: hash(previous_hash + content_hash)
└── signature: sign(chain_hash, private_key)
```

### Audit Log Inmutable

```
audit_log/
├── wal/                    # Write-ahead log
│   ├── 2026-03-01.wal
│   └── ...
├── index/                  # Índices para búsqueda
│   ├── by_source/
│   ├── by_target/
│   ├── by_type/
│   └── by_conversation/
└── snapshots/              # Snapshots periódicos
```

**Ver documento completo:** [08-FLUJOS/01-mensaje-bus.md](../08-FLUJOS/01-mensaje-bus.md)

---

## 15. Doble Comprobación

### Mecanismo de Validación en Cascada

```
┌─────────────────────────────────────────────────────────────────┐
│                   OUTPUT GENERATION                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. EJECUTOR genera output                                     │
│         │                                                       │
│         ▼                                                       │
│  2. ARCHIVADOR valida (Tri-agent interno)                      │
│         │                                                       │
│         ▼                                                       │
│  3. CHIEF revisa (Domain level)                                │
│         │                                                       │
│         ▼                                                       │
│  4. AI-IN-THE-LOOP verifica (Automated)                        │
│         │                                                       │
│    ┌────┴────┐                                                  │
│    │         │                                                  │
│  PASS      FAIL                                                 │
│    │         │                                                  │
│    ▼         ▼                                                  │
│  5a. ¿CROSS-UNIT?  5b. Request revision                        │
│      (si crítico)                                               │
│    │                                                            │
│    ▼                                                            │
│  6. ¿REQUIERE HUMANO?                                          │
│    │                                                            │
│    ├── Sí → Solicitar aprobación                               │
│    │         │                                                  │
│    │         ▼                                                  │
│    │    HUMANO aprueba/rechaza                                 │
│    │                                                            │
│    └── No → Entregar output                                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Tabla de Comprobaciones

| Punto | Validador | Criterio | Acción si Falla |
|-------|-----------|----------|-----------------|
| **1** | Ejecutor | Output generado | Regenerar |
| **2** | Archivador | Coherencia interna | Iterar |
| **3** | Chief | Calidad + políticas | Solicitar revisión |
| **4** | AI Gate | Anomalías + hechos | Flag + revisar |
| **5** | Cross-Unit | Segunda opinión | Resolver discrepancia |
| **6** | Human | Aprobación crítica | Bloquear hasta aprobar |

---

## 16. Documentación Técnica Completa

### Documentos Core

| Documento | Descripción |
|-----------|-------------|
| [02-validacion.md](../08-FLUJOS/02-validacion.md) | Validación multicapa, AI/HiL |
| [01-mensaje-bus.md](../08-FLUJOS/01-mensaje-bus.md) | Mensajería auditable |
| [00-arquitectura-memoria.md](../09-MEMORIA/00-arquitectura-memoria.md) | 4 memorias independientes |
| [00-overview.md](../06-NIVEL-2-ESPECIALISTAS/00-overview.md) | Creación dinámica de dominios |
| [00-knowledge-engine.md](../10-CONOCIMIENTO/00-knowledge-engine.md) | 5 capas de conocimiento |

### Documentos de Arquitectura

| Documento | Descripción |
|-----------|-------------|
| [03-router-dominios.md](../08-FLUJOS/03-router-dominios.md) | Sistema de routing |
| [00-arquitectura-maestra.md](./00-arquitectura-maestra.md) | Arquitectura completa del sistema |
| [01-stack-tecnologico.md](./01-stack-tecnologico.md) | Stack tecnológico |
| [02-modelos-ia.md](./02-modelos-ia.md) | Modelos de IA |
| [00-comunicaciones.md](../08-FLUJOS/00-comunicaciones.md) | Comunicaciones R-P-V |

---

## Referencias

- [00-OPENCLAW-SYSTEM.md](../00-OPENCLAW-SYSTEM.md) - Descripción general del sistema
- [PM2 Documentation](https://pm2.keymetrics.io/docs/)
- [LangChain Documentation](https://python.langchain.com/)
- [SQLite-vec](https://github.com/asg017/sqlite-vec)

---

**Documento:** Arquitectura Maestra
**Ubicación:** `docs/01-SISTEMA/00-arquitectura-maestra.md`
**Versión:** 2.1.0
**Fecha:** 2026-03-09
