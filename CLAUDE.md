# CLAUDE.md

Este archivo proporciona guía a Claude Code (claude.ai/code) al trabajar con código en este repositorio.

## Resumen del Proyecto

OPENCLAW-system es un **sistema multi-agente jerárquico** diseñado para emular organizaciones humanas estructuradas. El sistema combina orquestación, especialización por dominio y unidades de verificación tri-agente para producir salidas estables y verificables a lo largo del tiempo.

**Framework Base:** OpenClaw v2026.3.8 (20+ canales, 30+ proveedores IA)

---

## Jerarquía del Sistema (4 Niveles)

```
┌─────────────────────────────────────────────────────────┐
│  NIVEL SIS — ORQUESTADOR (unidad tri-agente)            │
│  Punto de entrada, coordinación global, ruteo dominios   │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│  NIVEL JEF — JEFES DE DOMINIO (agentes simples)         │
│  JEF-CON | JEF-ING | JEF-OPE | JEF-RHU | JEF-REX | JEF-COM │
│  Decisiones estratégicas, coordinación de dominio        │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│  NIVEL ESP — UNIDADES ESPECIALISTAS (tri-agentes)        │
│  ESP-DES | ESP-INF | ESP-HOS | ESP-ACA | etc.            │
│  Ejecución con validación interna                        │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│  NIVEL SUB — SUBAGENTES EFÍMEROS                         │
│  Trabajadores temporales, sin memoria, mueren tras tarea │
└─────────────────────────────────────────────────────────┘
```

### Por Qué Esta Estructura

| Nivel | Tipo | Razón |
|-------|------|-------|
| SIS | tri-agente | Robustez central para coordinación |
| JEF | agente simple | Eficiencia para decisiones estratégicas |
| ESP | tri-agente | Validación + calidad de ejecución |
| SUB | trabajadores | Escalabilidad para tareas paralelas |

---

## Formato de ID

```
LLL-DDD-TTT-SSS-nombre_descriptivo
│││ │││ │││ └─── SSS: Secuencia (001-999)
│││ │││ ││└──── TTT: Tipo (3 letras español, MAYÚSCULAS)
│││ │││ └────── DDD: Dominio (3 letras español, MAYÚSCULAS)
│││ └────────── LLL: Nivel (3 letras español, MAYÚSCULAS)
└────────────── nombre_descriptivo: Minúsculas con guiones bajos
```

### Códigos

| Categoría | Códigos |
|-----------|---------|
| **Niveles** | SIS (Sistema), JEF (Jefatura), ESP (Especialista), SUB (Subagente) |
| **Dominios** | SMA, BIB, CON, ING, OPE, RHU, REX, COM, DES, INF, HOS, ACA, GEN, CRI, FIN, DEP, IDI |
| **Tipos** | CFG, UNI, DIR, EJE, ARC, CNO, MEM, HER, PRO, PLA, REG |

---

## Estructura de Unidad Tri-Agente

Toda unidad especialista del Nivel ESP usa el patrón Triunvirato:

```
Unidad Especialista
│
├── Director    → Planificación, estrategia, delegación
├── Ejecutor    → Ejecución, cálculos, generación
└── Archivador  → Validación, documentación, actualización memoria
```

### Flujo de Responsabilidad

```
Solicitud → Director (planifica) → Ejecutor (ejecuta) → Archivador (valida) → Respuesta
               │                      │                      │
               └──────────────────────┴──────────────────────┘
                         Verificación interna
```

---

## Interfaz de Usuario: Comandos Namespace

Los usuarios NO interactúan con agentes internos directamente. La interacción ocurre a través de **namespaces de dominio**:

```
/dev        → Desarrollo, código, arquitectura
/infra      → Infraestructura, DevOps, servidores
/crypto     → Criptomonedas, blockchain
/inversiones → Inversiones, finanzas
/hosteleria → Hostelería, gastronomía
/fitness    → Deportes, entrenamiento, salud
/academico  → Oposiciones, estudio, tutoría
/english    → Aprendizaje de idiomas
```

### Modos de Enrutamiento

1. **Namespace explícito**: `/dev diseñar arquitectura cluster`
2. **Lenguaje natural implícito**: `"Diseñar una infraestructura distribuida"` → Enrutador detecta dominio automáticamente

Cuando un dominio no existe, la **Fábrica de Agentes** lo crea dinámicamente.

---

## Seis Jefes de Dominio (Catedráticos)

| Jefe | ID | Dominio | Herramientas Principales |
|------|-----|---------|--------------------------|
| **Conocimiento** | JEF-CON-UNI-001 | Conocimiento, documentación | GPT Researcher, Engram |
| **Ingeniería** | JEF-ING-UNI-001 | Ingeniería, arquitectura, calidad | GPT Researcher, CI/CD |
| **Operaciones** | JEF-OPE-UNI-001 | Operaciones, procesos, automatización | Sistemas monitoreo |
| **Recursos Humanos** | JEF-RHU-UNI-001 | RRHH, talento, **Fábrica Agentes** | Engram |
| **Relaciones Externas** | JEF-REX-UNI-001 | Relaciones externas, estrategia | Canales comunicación |
| **Comunicación** | JEF-COM-UNI-001 | Comunicaciones internas | Sistemas mensajería |

**Importante:** Los Jefes son responsables de la calidad final de la salida antes de presentar al usuario. Delegan trabajo pero NO aprobación.

---

## Motor de Conocimiento (5 Capas)

```
┌─────────────────────────────────────────────────────────┐
│  CAPA 1: Conocimiento del Modelo Base                   │
│  Conocimiento general del LLM (matemáticas, lógica)     │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│  CAPA 2: Bibliotecas Académicas Locales                 │
│  Manuales universitarios, libros técnicos, docs dominio │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│  CAPA 3: Estándares y Normativas Técnicas               │
│  ISO, IEEE, regulaciones oficiales, estándares industria│
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│  CAPA 4: Memoria del Sistema (Lecciones Aprendidas)     │
│  Decisiones tomadas, soluciones probadas, errores       │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│  CAPA 5: Fuentes de Investigación Externa               │
│  Papers académicos, fuentes verificadas (NO blogs)      │
└─────────────────────────────────────────────────────────┘
```

### Prioridad de Consulta

1. Memoria del sistema → 2. Fuentes personales → 3. Bibliotecas académicas → 4. Estándares → 5. Investigación externa

---

## Arquitectura de Memoria (4 Tipos)

| Tipo de Memoria | Ámbito | Almacenamiento |
|-----------------|--------|----------------|
| **Memoria de Agente** | Especialista individual | BD vectorial por agente |
| **Memoria de Unidad** | Compartida en tri-agente | Almacenamiento de unidad |
| **Memoria de Dominio** | Todos especialistas del dominio | Base conocimiento dominio |
| **Memoria Global** | Todo el sistema | Biblioteca conocimiento central |

---

## Fábrica de Agentes (Sistema RRHH)

Ubicada bajo JEF-RHU, responsable de crear nuevos especialistas cuando no existen dominios:

```
Usuario: /floristeria diseñar decoraciones boda

Sistema:
1. Enrutador detecta que dominio "floristeria" no existe
2. Fábrica de Agentes crea nuevo dominio usando plantilla
3. Plantilla + fuente conocimiento + configuración = Nueva unidad especialista
4. Dominio registrado en Registro de Agentes
5. Solicitud enrutada a nueva Unidad Floristería
```

---

## Estructura del Repositorio

```
OPENCLAW-system/
│
├── sistema/                    # Nivel SIS - Configuración
│   └── configuracion/
│
├── biblioteca/                 # Nivel SIS - Recursos compartidos
│   ├── protocolos/
│   ├── plantillas/
│   └── registros/
│
├── jefaturas/                  # Nivel JEF - Jefes de dominio
│   ├── conocimiento/
│   ├── ingenieria/
│   ├── operaciones/
│   ├── recursos_humanos/
│   ├── relaciones_externas/
│   └── comunicacion/
│
├── especialistas/              # Nivel ESP - Unidades especializadas
│   ├── desarrollo/
│   ├── infraestructura/
│   ├── hosteleria/
│   ├── academico/
│   ├── general/
│   ├── criptomonedas/
│   ├── finanzas/
│   ├── deportes/
│   └── idiomas/
│
├── docs/                       # Documentación
├── config/                     # Configuración adicional
└── scripts/                    # Scripts de control
```

---

## Comandos Principales

### Control de Herramientas

```bash
./scripts/tools-control.sh gpt-researcher start|stop|status|logs
./scripts/tools-control.sh maestro start|stop|status|logs
./scripts/tools-control.sh engram stats|search|save|context
./scripts/tools-control.sh status  # Verificar todas las herramientas
```

### Endpoints de Herramientas

| Herramienta | Puerto | Caso de Uso |
|-------------|--------|-------------|
| GPT Researcher | 11020 | Investigación web rápida |
| MAESTRO | 80 | Investigación RAG profunda multi-agente |
| Engram | MCP | Memoria persistente |

---

## Selección de Modelos Z.AI

| Modelo | Caso de Uso | Cuota |
|--------|-------------|-------|
| **glm-5** | Arquitectura compleja, refactors | 3x pico, 2x fuera-pico |
| **glm-4.7** | Desarrollo diario, revisión código | 1x |
| **glm-4.6/4.6v** | Tareas visión, análisis UI | 1x |
| **glm-4.5-air/flash** | Consultas rápidas, programación pareada | 1x |

---

## Dependencias Externas

- **JartOS**: Ecosistema padre en `/Users/ruben/JartOS/`
- **OpenClaw**: Framework base (v2026.3.8)
- **PM2**: Gestión de procesos
- **Docker**: Ejecución en sandbox

---

## Rutas de Referencia Rápida

| Documento | Ruta |
|-----------|------|
| Visión general | `INDEX.md` |
| Configuración sistema | `sistema/configuracion/SIS-SMA-CFG-001-sistema.yaml` |
| Protocolos | `biblioteca/protocolos/` |
| Plantillas | `biblioteca/plantillas/` |
| Jefaturas | `jefaturas/` |
| Especialistas | `especialistas/` |

---

## Convenciones de Nomenclatura

### Nombres de Archivo

- **Formato:** `LLL-DDD-TTT-SSS-nombre_descriptivo.ext`
- **Ejemplo:** `ESP-DES-HER-001-herramientas.yaml`

### Contenido

- **Ids:** Siempre en MAYÚSCULAS con guiones
- **Nombres descriptivos:** Siempre en minúsculas con guiones bajos
- **Todo en español:** Sin términos en inglés

### Mapeo de Términos

**⚠️ REGLA CRÍTICA: Usar SIEMPRE terminología española en documentación y código.**

| Inglés (PROHIBIDO) | Español (OBLIGATORIO) | Contexto |
|-------------------|----------------------|----------|
| ~~Manager~~ | **Director** | Rol de planificación en tri-agente |
| ~~Worker~~ | **Ejecutor** | Rol de ejecución en tri-agente |
| ~~Archivist~~ | **Archivador** | Rol de validación en tri-agente |
| ~~Unit~~ | **Unidad** | Conjunto de agentes |
| ~~Domain~~ | **Dominio** | Área de especialización |
| ~~Chief~~ | **Jefe** | Catedrático de dominio |
| ~~Router~~ | **Enrutador** | Sistema de routing |
| ~~Factory~~ | **Fábrica** | Creador de agentes |
| ~~Engine~~ | **Motor** | Sistema de procesamiento |
| ~~Knowledge~~ | **Conocimiento** | Base de conocimiento |
| ~~Memory~~ | **Memoria** | Sistema de memoria |
| ~~Gear~~ | **Engranaje** | Componente del sistema |
| ~~Skill~~ | **Habilidad** | Capacidades de agente |
| ~~Tool~~ | **Herramienta** | Utilidades disponibles |

**Excepciones:** Nombres de archivos de configuración de OpenClaw (ecosystem.config.js) y nombres de funciones internas del framework base.
