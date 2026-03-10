# OPENCLAW-system

## Sistema Multi-Agente Jerárquico con Arquitectura Mixture of Experts

**Versión:** 2.0 | **Fecha:** 2026-03-09 | **Framework Base:** OpenClaw v2026.3.8

---

## Resumen Ejecutivo

OPENCLAW-system es un **framework de orquestación de agentes de inteligencia artificial** que implementa una arquitectura jerárquica de 4 niveles, inspirada en las estructuras organizativas humanas. El sistema combina el patrón **Triunvirato** (tres roles especializados por unidad) con un sistema de **validación multicapa** para producir outputs estables, auditables y verificables.

### Propósito Principal

Resolver los problemas fundamentales de los sistemas multi-agente actuales:
- **Alucinaciones no detectadas** → Validación multicapa obligatoria
- **Inconsistencia temporal** → 4 tipos de memoria persistente
- **Falta de auditoría** → Sistema de mensajería con cadena de integridad
- **Ejecución sin supervisión** → Human-in-the-loop en operaciones críticas
- **Escalado incontrolado** → Agent Factory con templates controlados

---

## 1. Introducción y Contexto

### 1.1 Qué es OPENCLAW-system

OPENCLAW-system es una **base documental y de configuración** para desplegar un sistema multi-agente personalizado basado en el framework OpenClaw. El proyecto proporciona:

- Arquitectura jerárquica bien definida (4 niveles)
- Patrón Triunvirato (Director-Ejecutor-Archivador)
- Sistema de 6 Catedráticos (Domain Chiefs)
- Motor de conocimiento estructurado (5 capas)
- Sistema de memoria multicapa (4 tipos)
- Validación multicapa (5 capas)

### 1.2 Qué NO es

- No es un chatbot simple
- No es un sistema de agentes "swarm" sin estructura
- No es un reemplazo directo de ChatGPT/Claude
- No es un sistema completamente autónomo (requiere supervisión)

### 1.3 Posicionamiento

| vs. LangChain | OPENCLAW añade jerarquía, validación multicapa y memoria estructurada |
|---------------|-----------------------------------------------------------------------|
| vs. AutoGen   | OPENCLAW añade supervisión humana, auditoría y patrón Triunvirato     |
| vs. CrewAI    | OPENCLAW añade 4 niveles jerárquicos y Knowledge Engine               |
| vs. OpenClaw  | OPENCLAW-system es una implementación específica con documentación completa |

---

## 2. Arquitectura del Sistema

### 2.1 Los 4 Niveles Jerárquicos

```
┌─────────────────────────────────────────────────────────────────┐
│  NIVEL 0 — ORQUESTADOR (tri-agente)                             │
│  Punto de entrada, coordinación global, routing de dominios     │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│  NIVEL 1 — CATEDRÁTICOS (6 agentes individuales)                │
│  CKO | CEngO | COO | CHO | CSRO | CCO                           │
│  Decisiones estratégicas, coordinación de dominio               │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│  NIVEL 2 — UNIDADES ESPECIALISTAS (tri-agentes)                 │
│  DEV Unit | Infra Unit | Research Unit | etc.                   │
│  Ejecución con validación interna                               │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│  NIVEL 3 — SUBAGENTES EFÍMEROS                                  │
│  Trabajadores temporales, sin memoria, mueren al completar      │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Justificación de la Estructura

| Nivel | Tipo | Razón |
|-------|------|-------|
| 0 | Tri-agente | Robustez central para coordinación crítica |
| 1 | Agente simple | Eficiencia para decisiones estratégicas |
| 2 | Tri-agente | Validación + calidad de ejecución |
| 3 | Workers simples | Escalabilidad para tareas paralelas |

### 2.3 Patrón Triunvirato

Cada unidad de trabajo (Niveles 0 y 2) está compuesta por tres roles especializados:

| Rol | Responsabilidad | NO Puede |
|-----|-----------------|----------|
| **Director** | Planificar, delegar, revisar | Ejecutar comandos directamente |
| **Ejecutor** | Ejecutar, operar herramientas | Tomar decisiones de alto nivel |
| **Archivador** | Validar, documentar, memorizar | Modificar el resultado |

**Flujo:** `Input → Director (planea) → Ejecutor (ejecuta) → Archivador (valida) → Output`

---

## 3. Los Seis Catedráticos (Level 1)

| Catedrático | Código | Dominio | Namespaces |
|-------------|--------|---------|------------|
| **CKO** | `00-cko` | Conocimiento, documentación | `/knowledge`, `/oposiciones` |
| **CEngO** | `00-cengo` | Ingeniería, arquitectura, calidad | `/dev`, `/infra` |
| **COO** | `00-coo` | Operaciones, procesos | `/hosteleria`, `/f&b` |
| **CHO** | `00-cho` | Talento, Agent Factory | `/fitness`, nuevos dominios |
| **CSRO** | `00-csro` | Relaciones externas, estrategia | `/crypto`, `/inversiones` |
| **CCO** | `00-cco` | Comunicaciones internas | `/english`, comunicación |

**Principio clave:** El Catedrático que entrega un resultado es **responsable de su calidad**. Puede delegar trabajo, pero NO la aprobación final.

---

## 4. Sistema de Memoria (4 Tipos)

| Tipo | Scope | Contenido | Storage |
|------|-------|-----------|---------|
| **Memoria de Agente** | Individual | Contexto personal | Vector DB individual |
| **Memoria de Unidad** | Tri-agente | Colaboración M/W/A | Unit-level storage |
| **Memoria de Dominio** | Todo el dominio | Conocimiento de /dev, /infra, etc. | Domain KB |
| **Memoria Global** | Sistema completo | Decisiones arquitectónicas, lecciones | Central library |

---

## 5. Motor de Conocimiento (5 Capas)

```
CAPA 1: Foundation Model Knowledge
        Conocimiento general del LLM (matemáticas, lógica, programación)

CAPA 2: Local Academic Libraries
        Manuales universitarios, libros técnicos, textos especializados

CAPA 3: Technical Standards & Norms
        ISO, IEEE, normativas nacionales, protocolos técnicos

CAPA 4: System Memory (Lessons Learned)
        Decisiones tomadas, soluciones probadas, errores detectados

CAPA 5: External Research Sources
        Papers académicos, fuentes verificadas (NO blogs ni opiniones)
```

**Prioridad de consulta:** Memoria → Fuentes personales → Académicas → Estándares → Externa

---

## 6. Sistema de Validación (5 Capas)

```
CAPA 5: HUMAN-IN-THE-LOOP
        Aprobación humana para operaciones críticas y destructivas

CAPA 4: CROSS-UNIT VALIDATION
        Segunda opinión de otra unidad especialista

CAPA 3: DOMAIN CHIEF REVIEW
        Revisión por Catedrático antes de entrega

CAPA 2: AI-IN-THE-LOOP
        Supervisión automática por IA en puntos críticos

CAPA 1: TRI-AGENT VALIDATION
        Validación interna en la unidad Triunvirato
```

---

## 7. Interfaz de Usuario

### Sistema de Namespaces

El usuario interactúa mediante **namespaces de dominio**:

```
/dev        → Desarrollo, programación, arquitectura
/infra      → Infraestructura, DevOps, servidores
/crypto     → Criptomonedas, blockchain
/inversiones → Inversión, finanzas
/hosteleria → Hostelería, gastronomía, F&B
/fitness    → Deportes, entrenamiento
/oposiciones → Preparación de exámenes
/english    → Aprendizaje de idiomas
```

### Routing Inteligente

Si no se especifica namespace, el sistema realiza **clasificación semántica automática**:

```
"Diseñar una arquitectura distribuida"
         ↓
Router detecta: /dev (confianza 0.92)
         ↓
Route a: CEngO → DEV Unit
```

---

## 8. Agent Factory

El sistema puede **crear nuevos dominios dinámicamente**:

```
/floristeria diseñar decoración boda
         ↓
Router detecta: dominio no existe
         ↓
Agent Factory (CHO):
  1. Selecciona template
  2. Configura con conocimiento
  3. Crea unidad tri-agente
  4. Registra en sistema
         ↓
Request enrutado a nueva Floristry Unit
```

---

## 9. Stack Tecnológico

| Componente | Tecnología |
|------------|------------|
| **Core Framework** | OpenClaw v2026.3.8 |
| **Runtime** | Node.js 23.x |
| **Gestor de paquetes** | pnpm 10.x |
| **LLM por defecto** | Ollama + Llama 3.2 (3B) |
| **Gestor de procesos** | PM2 >= 5.4.3 |
| **Vector Database** | SQLite-vec, LanceDB |
| **Sandbox** | Docker (rootless mode) |

### Proveedores de IA Soportados

- **Por defecto:** Ollama local (sin API tokens necesarios)
- **Opcionales:** OpenAI, Anthropic, Google AI, Z.AI, LM Studio, etc.

---

## 10. Seguridad

### Vulnerabilidades Conocidas y Mitigaciones

| Componente | Vulnerabilidad | Mitigación |
|------------|----------------|------------|
| Docker runc | CVE-2024-21626 | Actualizar a runc >= 1.1.12 |
| PM2 < 5.4.3 | Command Injection | Actualizar a PM2 >= 5.4.3 |
| Ollama | Exposición red | Configurar `OLLAMA_HOST=127.0.0.1:11434` |
| Docker | Privileged containers | Usar `--cap-drop=ALL`, rootless mode |

### Configuración Segura

- Gateway en `127.0.0.1:18789` (no expuesto)
- Docker sandbox con `networkMode: "none"`, `capDrop: ALL`
- Exec-Approvals habilitado para comandos peligrosos
- Safe-Bin Policy activa

---

## 11. Estado del Proyecto

| Componente | Estado |
|------------|--------|
| Arquitectura | ✅ Definida |
| Documentación | ✅ Completa |
| Especificaciones | ✅ Detalladas |
| Implementación | ⏳ Pendiente |
| Tests | ⏳ Pendiente |
| Producción | ⏳ Pendiente |

---

## 12. Estructura del Repositorio

```
OPENCLAW-system/
├── README.md                    # Visión general
├── 00-PROYECTO.md               # Este documento
├── CLAUDE.md                    # Instrucciones para Claude Code
├── docs/
│   ├── 01-SISTEMA/              # Visión general del sistema
│   ├── 02-INSTANCIAS/           # Instancias OpenClaw
│   ├── 03-CLUSTERS/             # Clusters (CKO_CORE, etc.)
│   ├── 04-NIVEL-0/              # Orquestador
│   ├── 05-NIVEL-1/              # Catedráticos
│   ├── 06-NIVEL-2/              # Especialistas
│   ├── 07-NIVEL-3/              # Subagentes
│   ├── 08-FLUJOS/               # Flujos de comunicación
│   ├── 09-MEMORIA/              # Arquitectura de memoria
│   ├── 10-CONOCIMIENTO/         # Motor de conocimiento
│   ├── 11-SEGURIDAD/            # Seguridad
│   ├── 12-IMPLEMENTACION/       # Guías de instalación
│   ├── 13-OPERACIONES/          # Operaciones
│   ├── 14-DESARROLLO/           # Desarrollo
│   ├── 15-REFERENCIA/           # Referencia
│   └── 99-ANEXOS/               # Hojas de ruta prácticas
├── scripts/                     # Scripts de automatización
├── config/                      # Templates de configuración
└── .claude/                     # Configuración Claude Code
```

---

## 13. Referencias

- [OpenClaw Framework](https://github.com/openclaw/openclaw) - Core framework
- [Ollama](https://ollama.com) - LLM local
- [PM2](https://pm2.keymetrics.io) - Process manager
- [SQLite-vec](https://github.com/asg017/sqlite-vec) - Vector database

---

**Documento:** Descripción Académica del Proyecto
**Versión:** 2.0
**Fecha:** 2026-03-09
**Autores:** Equipo de Arquitectura OPENCLAW-system
