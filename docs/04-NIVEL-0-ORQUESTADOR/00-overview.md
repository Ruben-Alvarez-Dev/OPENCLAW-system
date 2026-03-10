# Nivel 0 - Orquestador

**ID:** DOC-SIS-ORQ-001
**Tipo:** Unidad Tri-Agente | **Función:** Punto de entrada y coordinación global
**Versión:** 2.1.0
**Fecha:** 2026-03-09

---

## Concepto

El **Orquestador** es el punto de entrada único del sistema. Recibe todas las peticiones del usuario, las clasifica, las enruta al dominio apropiado y coordina la comunicación entre diferentes partes del sistema.

---

## Estructura Tri-Agente

```
ORQUESTADOR (Nivel 0)
│
├── Director
│   ├── Recibe input del usuario
│   ├── Clasifica la petición
│   ├── Decide routing a Catedrático
│   └── Coordina respuestas multi-dominio
│
├── Ejecutor
│   ├── Ejecuta operaciones de routing
│   ├── Consulta Registro de Agentes
│   ├── Gestiona estado de sesiones
│   └── Ejecuta comandos de coordinación
│
└── Archivador
    ├── Registra todas las decisiones
    ├── Mantiene estado global
    ├── Audita flujos de comunicación
    └── Actualiza memoria del sistema
```

---

## Responsabilidades

### 1. Gestión de Entrada

| Función | Descripción |
|---------|-------------|
| **Recepción** | Aceptar peticiones de todos los canales |
| **Parsing** | Extraer namespace y contenido |
| **Validación** | Verificar formato y permisos |
| **Clasificación** | Determinar dominio y complejidad |

### 2. Routing

| Función | Descripción |
|---------|-------------|
| **Namespace routing** | Enrutar por prefijo `/dev`, `/infra`, etc. |
| **Semantic routing** | Clasificar por contenido si no hay namespace |
| **Load balancing** | Distribuir carga entre unidades |
| **Failover** | Redirigir si una unidad no está disponible |

### 3. Coordinación Global

| Función | Descripción |
|---------|-------------|
| **Multi-dominio** | Coordinar peticiones que requieren varios dominios |
| **Estado global** | Mantener contexto del sistema |
| **Conflictos** | Resolver conflictos entre dominios |
| **Prioridades** | Gestionar colas de prioridad |

### 4. Escalado

| Función | Descripción |
|---------|-------------|
| **Escala a cero** | Desactivar recursos no utilizados |
| **Recuperación** | Restaurar estado de backups |
| **Métricas** | Reportar progreso a monitoreo |
| **Alertas** | Notificar anomalías |

---

## Flujo de Petición

```
┌─────────────────────────────────────────────────────────────────┐
│                    PETICIÓN DEL USUARIO                         │
│                    "/dev diseñar API REST"                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ORQUESTADOR - Director                       │
│  1. Recibe petición                                             │
│  2. Detecta namespace: /dev                                    │
│  3. Clasifica: ingeniería software, complejidad media          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ORQUESTADOR - Ejecutor                       │
│  1. Consulta Registro de Agentes                                │
│  2. Verifica disponibilidad de JEF-ING                         │
│  3. Prepara contexto de sesión                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ORQUESTADOR - Archivador                     │
│  1. Registra decisión de routing                               │
│  2. Crea trace_id para seguimiento                             │
│  3. Actualiza métricas                                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    Route a: JEF-ING (Nivel 1)
```

---

## Interfaces

### Entrada

| Canal | Formato | Descripción |
|-------|---------|-------------|
| **CLI** | Texto | Línea de comandos |
| **API REST** | JSON | Integración programática |
| **WebSocket** | JSON | Tiempo real |
| **Telegram** | Texto | Bot de Telegram |

### Salida

| Destino | Formato | Descripción |
|---------|---------|-------------|
| **Nivel 1** | Mensaje interno | A Catedráticos |
| **Usuario** | Texto/JSON | Respuesta final |
| **Logs** | JSON estructurado | Auditoría |
| **Métricas** | Prometheus | Monitoreo |

---

## Configuración

```yaml
orchestrator:
  bind: "127.0.0.1"
  port: 18789

  routing:
    default_timeout: 30000
    max_concurrent: 100

  validation:
    input_schema: true
    sanitize_html: true

  logging:
    level: info
    format: json
```

---

## Métricas Clave

| Métrica | Descripción | Umbral |
|---------|-------------|--------|
| `orchestrator.requests.total` | Peticiones totales | - |
| `orchestrator.requests.latency` | Latencia de routing | < 100ms |
| `orchestrator.routing.errors` | Errores de routing | < 0.1% |
| `orchestrator.queue.length` | Cola pendiente | < 50 |

---

**Documento:** Nivel 0 - Orquestador
**Ubicación:** `docs/04-NIVEL-0-ORQUESTADOR/00-overview.md`
**Versión:** 2.1.0
**Fecha:** 2026-03-09
