# Arquitectura Holística OPENCLAW-system

**Propietario:** Ruben
**Fecha:** 2026-03-10
**Versión:** 2.0 - Arquitectura Custom (sin npm package)
**Estado:** DISEÑO ENTERPRISE

---

## 1. Visión Global

El sistema OPENCLAW requiere una arquitectura **holística** que garantice:

- **Control**: Gobernanza, policies, compliance
- **Observabilidad**: Logs, métricas, traces, alertas
- **Seguridad**: Auth, autorización, encriptación, aislamiento
- **Escalabilidad**: Fractal, multinivel, distribuido
- **Resiliencia**: Fault tolerance, circuit breakers, rollback

### Principios Fundamentales

1. **Todo es observable**: Cada acción genera logs, métricas y traces
2. **Todo es gobernable**: Policies controlan cada decisión
3. **Todo es auditable**: Historial completo de cada operación
4. **Todo es seguro**: Encriptación, aislamiento, principio mínimo privilegio
5. **Todo escala**: Patrón fractal replicable en cada nivel

---

## 2. Arquitectura de 7 Capas

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CAPA 7: GOBERNANZA                                 │
│    Policies · Compliance · Auditoría · Control de Cambios                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                           CAPA 6: OBSERVABILIDAD                             │
│    Logs · Métricas · Traces · Alertas · Dashboards                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                           CAPA 5: SEGURIDAD                                  │
│    Auth · Autorización · Encriptación · Aislamiento · Vault                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                           CAPA 4: COMUNICACIÓN                               │
│    Pipelines · Event Bus · Message Queue · Ring Protocol                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                           CAPA 3: MEMORIA & CONOCIMIENTO                     │
│    RAG Jerárquico · Vector DB · Knowledge Graph · Learning Engine           │
├─────────────────────────────────────────────────────────────────────────────┤
│                           CAPA 2: ORQUESTACIÓN                               │
│    Tri-Agentes · Catedráticos · Sistema · Flujos de Decisión                │
├─────────────────────────────────────────────────────────────────────────────┤
│                           CAPA 1: INFRAESTRUCTURA                            │
│    Custom Gateways (Fastify) · Redis · PostgreSQL · LanceDB · Object Store  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Capa 1: Infraestructura

### Stack Tecnológico

| Componente | Tecnología | Propósito |
|------------|------------|-----------|
| **AI Gateway** | Fastify + Node.js | Multi-agente, WebSocket, tools |
| **Message Broker** | Redis (Pub/Sub + Streams) | Comunicación, colas, caché |
| **Primary DB** | PostgreSQL | Estado persistente, auditoría |
| **Vector DB** | LanceDB | RAG, embeddings, búsqueda semántica |
| **Object Store** | MinIO / S3 | Archivos, artefactos, backups |
| **Secrets** | HashiCorp Vault | API keys, credenciales, certificados |
| **Observability** | Prometheus + Grafana + Loki | Métricas, dashboards, logs |

### Topología de Red

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              RED PRIVADA                                     │
│                                                                              │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐       │
│  │   MAC MINI      │     │   MACBOOK       │     │   VPS HETZNER   │       │
│  │   (Core)        │     │   (LLM Server)  │     │   (Gateway)     │       │
│  │                 │     │                 │     │                 │       │
│  │  • Fastify GW   │     │  • Ollama       │     │  • Fastify GW   │       │
│  │  • Redis        │     │  • GPU Compute  │     │  • Public API   │       │
│  │  • PostgreSQL   │     │                 │     │  • Tailscale    │       │
│  │  • LanceDB      │     │                 │     │                 │       │
│  └─────────────────┘     └─────────────────┘     └─────────────────┘       │
│         │                        │                       │                  │
│         └────────────────────────┴───────────────────────┘                  │
│                              Tailscale Mesh                                  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Puertos y Servicios

| Puerto | Servicio | Alcance |
|--------|----------|---------|
| 18789 | Fastify Gateway (concilios) | localhost + Tailscale |
| 6379 | Redis | localhost |
| 5432 | PostgreSQL | localhost |
| 9090 | Prometheus | localhost + Tailscale |
| 3000 | Grafana | localhost + Tailscale |
| 11434 | Ollama | localhost + Tailscale |
| 8200 | Vault | localhost |

---

## 4. Capa 2: Orquestación

### 4.1 Jerarquía Fractal

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  NIVEL L5: META-SISTEMA                                                      │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  Múltiples sistemas OPENCLAW conectados                                │  │
│  │  Inter-system communication, global governance                         │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
┌─────────────────────────────────────────────────────────────────────────────┐
│  NIVEL L4: SISTEMA (SIS)                                                     │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  Orquestador global                                                    │  │
│  │  • Routing de dominios                                                 │  │
│  │  • Coordinación entre Catedráticos                                     │  │
│  │  • System-wide policies                                                │  │
│  │  • Global memory & knowledge                                           │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
┌─────────────────────────────────────────────────────────────────────────────┐
│  NIVEL L3: DOMINIO (Catedráticos)                                            │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │ JEF-CON     │ │ JEF-ING     │ │ JEF-OPE     │ │ JEF-REX     │ ...       │
│  │ Conocimiento│ │ Ingeniería  │ │ Operaciones │ │ Relaciones  │           │
│  │             │ │             │ │             │ │             │           │
│  │ 1 agente    │ │ 1 agente    │ │ 1 agente    │ │ 1 agente    │           │
│  │ simple      │ │ simple      │ │ simple      │ │ simple      │           │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘           │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
┌─────────────────────────────────────────────────────────────────────────────┐
│  NIVEL L2: CONCILIO (Tri-Agente)                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  1 Gateway Fastify con 3 agentes                                       │  │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐                      │  │
│  │  │ DIRECTOR    │ │ EJECUTOR    │ │ ARCHIVADOR  │                      │  │
│  │  │ • Planifica │ │ • Ejecuta   │ │ • Valida    │                      │  │
│  │  │ • Coordina  │ │ • Produce   │ │ • Memoriza  │                      │  │
│  │  └─────────────┘ └─────────────┘ └─────────────┘                      │  │
│  │  + Communication Ring interno                                          │  │
│  │  + RAG compartido del concilio                                         │  │
│  │  + Memory propia del concilio                                          │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
┌─────────────────────────────────────────────────────────────────────────────┐
│  NIVEL L1: AGENTE (Proceso Node.js Base)                                    │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  Agente individual (proceso Node.js)                                    │  │
│  │  • Workspace propio                                                    │  │
│  │  • Memoria individual                                                  │  │
│  │  • RAG individual                                                      │  │
│  │  • Tools permitidas                                                    │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
┌─────────────────────────────────────────────────────────────────────────────┐
│  NIVEL L0: SUBAGENTE (Trabajadores Efímeros)                                 │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  Spawned on-demand                                                     │  │
│  │  • Sin memoria persistente                                             │  │
│  │  • Mueren tras completar tarea                                         │  │
│  │  • Reportan al agente padre                                            │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Interfaz Unificada por Nivel

**Cada nivel expone UNA interfaz unificada al nivel superior:**

```python
class FractalEntity:
    """
    Cada entidad en cualquier nivel se comporta como
    UNA SOLA instancia desde la perspectiva externa.
    """

    @property
    def unified_interface(self) -> UnifiedInterface:
        """
        Interfaz que ve el nivel superior.
        Oculta la complejidad interna.
        """
        return UnifiedInterface(
            id=self.id,
            level=self.level,
            capabilities=self.get_aggregated_capabilities(),
            memory=self.get_aggregated_memory(),
            rag=self.get_aggregated_rag(),
            invoke=self.invoke,  # Punto de entrada único
            status=self.status,  # Estado agregado
            metrics=self.metrics  # Métricas agregadas
        )

    async def invoke(self, request: Request) -> Response:
        """
        Punto de entrada único.
        El nivel superior solo ve: request → response
        """
        # 1. Log de entrada
        await self.audit_log.log_invoke(request)

        # 2. Verificar policies
        policy_result = await self.governance.check_policies(request)
        if not policy_result.allowed:
            raise PolicyViolationError(policy_result.reason)

        # 3. Procesar según nivel
        if self.level == Level.L1_AGENT:
            response = await self._process_as_agent(request)
        else:
            response = await self._coordinate_sub_entities(request)

        # 4. Log de salida
        await self.audit_log.log_response(response)

        # 5. Actualizar métricas
        await self.metrics.record(request, response)

        return response
```

---

## 5. Capa 3: Memoria & Conocimiento

### 5.1 Arquitectura de Memoria Multinivel

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     MEMORIA GLOBAL (L4 - Sistema)                            │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  PostgreSQL: system_memory                                            │  │
│  │  • Decisiones跨-dominio                                                │  │
│  │  • Patrones globales                                                   │  │
│  │  • Políticas del sistema                                               │  │
│  │  • Conocimiento compartido                                             │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     MEMORIA DE DOMINIO (L3 - Catedrático)                    │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │ MEM-CON     │ │ MEM-ING     │ │ MEM-OPE     │ │ MEM-REX     │           │
│  │ Conocimiento│ │ Ingeniería  │ │ Operaciones │ │ Relaciones  │           │
│  │             │ │             │ │             │ │             │           │
│  │ PostgreSQL  │ │ PostgreSQL  │ │ PostgreSQL  │ │ PostgreSQL  │           │
│  │ + LanceDB   │ │ + LanceDB   │ │ + LanceDB   │ │ + LanceDB   │           │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘           │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     MEMORIA DE CONCILIO (L2 - Tri-Agente)                    │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  LanceDB: concilium_memory                                            │  │
│  │  • Tabla: validated (conocimiento aprobado)                            │  │
│  │  • Tabla: pending (en revisión)                                        │  │
│  │  • Tabla: rejected (descartado)                                        │  │
│  │  • decision_log, patterns, errors                                      │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     MEMORIA DE AGENTE (L1 - Individual)                      │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐                           │
│  │ MEM-Director│ │ MEM-Ejecutor│ │ MEM-Archiv. │                           │
│  │             │ │             │ │             │                           │
│  │ SQLite      │ │ SQLite      │ │ SQLite      │                           │
│  │ + LanceDB   │ │ + LanceDB   │ │ + LanceDB   │                           │
│  │ (individual)│ │ (individual)│ │ (individual)│                           │
│  └─────────────┘ └─────────────┘ └─────────────┘                           │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 RAG Jerárquico

```python
class HierarchicalRAG:
    """
    RAG que busca en múltiples niveles con prioridad.
    """

    async def search(self, query: str, context: RequestContext) -> List[Fragment]:
        results = []

        # 1. RAG Individual (más relevante para el agente actual)
        individual = await self.individual_rag.search(
            query=query,
            agent_id=context.agent_id,
            limit=5
        )
        results.extend(self._annotate(individual, scope="individual", weight=1.0))

        # 2. RAG del Concilio (conocimiento validado por los 3)
        if context.concilium_id:
            concilium = await self.concilium_rag.search(
                query=query,
                concilium_id=context.concilium_id,
                status="validated",  # Solo conocimiento aprobado
                limit=5
            )
            results.extend(self._annotate(concilium, scope="concilium", weight=0.9))

        # 3. RAG del Dominio (conocimiento del área)
        if context.domain:
            domain = await self.domain_rag.search(
                query=query,
                domain=context.domain,
                limit=5
            )
            results.extend(self._annotate(domain, scope="domain", weight=0.8))

        # 4. RAG Global (conocimiento del sistema)
        global_results = await self.global_rag.search(
            query=query,
            limit=5
        )
        results.extend(self._annotate(global_results, scope="global", weight=0.7))

        # Re-rankear por relevancia + peso del scope
        return self._rerank(results, query)
```

### 5.3 Learning Encapsulation Pipeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    LEARNING ENCAPSULATION PIPELINE                           │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  STAGE 1: CAPTURE                                                    │    │
│  │  • Capturar request + response + contribuciones                      │    │
│  │  • Metadata: agentes, tiempos, decisiones                            │    │
│  │  • Guardar en raw_experiences (Redis Stream)                         │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                    │                                         │
│                                    ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  STAGE 2: EXTRACT                                                    │    │
│  │  • LLM extrae lección principal                                      │    │
│  │  • Identificar: qué funcionó, qué falló, principio                   │    │
│  │  • Generar embedding del fragmento                                   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                    │                                         │
│                                    ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  STAGE 3: VALIDATE (Archivador)                                      │    │
│  │  • Verificar contra requisitos                                       │    │
│  │  • Score de confianza (0-1)                                          │    │
│  │  • Decisión: approved / rejected / needs_review                      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                    │                                         │
│                          ┌───────┴───────┐                                   │
│                          │               │                                   │
│                    score >= 0.8      score < 0.8                            │
│                          │               │                                   │
│                          ▼               ▼                                   │
│  ┌─────────────────────────────┐ ┌─────────────────────────────┐            │
│  │  STAGE 4a: ENCAPSULATE      │ │  STAGE 4b: QUEUE            │            │
│  │  • Convertir a principio    │ │  • Enviar a revisión        │            │
│  │  • Condiciones de aplicación│ │  • Notificar al Director    │            │
│  │  • Anti-patrones           │ │  • Esperar validación       │            │
│  │  • Guardar en validated    │ │  • O descartar              │            │
│  └─────────────────────────────┘ └─────────────────────────────┘            │
│                                    │                                         │
│                                    ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  STAGE 5: PROPAGATE                                                  │    │
│  │  • Si es conocimiento de dominio → promover a RAG de dominio         │    │
│  │  • Si es conocimiento global → promover a RAG global                 │    │
│  │  • Indexar en vector DB correspondiente                              │    │
│  │  • Notificar a suscriptores                                          │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Capa 4: Comunicación

### 6.1 Pipeline de Comunicación

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         COMMUNICATION PIPELINE                               │
│                                                                              │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐  │
│  │ INGRESS │───►│  ROUTE  │───►│ PROCESS │───►│  LOG    │───►│ EGRESS  │  │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘  │
│       │              │              │              │              │         │
│       ▼              ▼              ▼              ▼              ▼         │
│  Validar        Determinar     Ejecutar       Registrar     Formatear     │
│  Auth           Destino        Acción         Trace         Respuesta     │
│  Rate Limit     Bindings       Tools          Metrics       Entregar      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 6.2 Event Bus Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           EVENT BUS (Redis Streams)                          │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  STREAM: requests                                                      │  │
│  │  • Todas las solicitudes entrantes                                     │  │
│  │  • Consumer groups por dominio                                         │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  STREAM: decisions                                                     │  │
│  │  • Decisiones tomadas por agentes                                      │  │
│  │  • Para auditoría y learning                                           │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  STREAM: events                                                        │  │
│  │  • Eventos del sistema                                                 │  │
│  │  • state changes, errors, alerts                                       │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  STREAM: learning                                                      │  │
│  │  • Experiencias para learning engine                                   │  │
│  │  • Procesadas por learning workers                                     │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  PUB/SUB: ring:{concilium_id}:{topic}                                 │  │
│  │  • Comunicación interna del concilio                                   │  │
│  │  • Topics: coord, tasks, validation, rpc                               │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 6.3 Message Protocol

```python
@dataclass
class Envelope:
    """Envelope estándar para todos los mensajes"""

    # Identificación
    id: str                    # UUID único
    trace_id: str              # Para distributed tracing
    correlation_id: str        # Para request-response

    # Routing
    source: EntityRef          # Quién envía
    destination: EntityRef     # A quién va

    # Clasificación
    type: MessageType          # request, response, event, command
    priority: Priority         # low, normal, high, critical
    ttl: int                   # Time to live en segundos

    # Contenido
    payload: Dict[str, Any]    # Datos del mensaje
    metadata: Dict[str, Any]   # Metadatos adicionales

    # Control
    created_at: float
    expires_at: float

    # Seguridad
    signature: str             # Firma del mensaje
    encrypted: bool            # Si el payload está encriptado

@dataclass
class EntityRef:
    """Referencia a una entidad en cualquier nivel"""
    level: Level               # L0-L5
    entity_id: str             # ID de la entidad
    domain: Optional[str]      # Dominio si aplica
    concilium: Optional[str]   # Concilio si aplica
    agent: Optional[str]       # Agente específico si aplica
```

---

## 7. Capa 5: Seguridad

### 7.1 Modelo de Seguridad Multinivel

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          SECURITY LAYERS                                     │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  LAYER 1: NETWORK                                                     │  │
│  │  • Tailscale mesh (autenticación mutua)                               │  │
│  │  • Firewall rules por servicio                                        │  │
│  │  • mTLS para comunicación interna                                     │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  LAYER 2: AUTHENTICATION                                              │  │
│  │  • API Keys en Vault                                                  │  │
│  │  • JWT tokens con expiración                                          │  │
│  │  • Session management en Redis                                        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  LAYER 3: AUTHORIZATION                                               │  │
│  │  • RBAC (Role-Based Access Control)                                   │  │
│  │  • Policies por nivel y dominio                                       │  │
│  │  • Principle of least privilege                                       │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  LAYER 4: DATA                                                        │  │
│  │  • Encriptación at-rest (PostgreSQL TDE)                              │  │
│  │  • Encriptación in-transit (TLS 1.3)                                  │  │
│  │  • PII handling con masking                                           │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  LAYER 5: AUDIT                                                       │  │
│  │  • Immutable audit log                                                │  │
│  │  • Tamper-evident storage                                             │  │
│  │  • Retention policies                                                 │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 7.2 Vault Integration

```python
class SecretsManager:
    """
    Gestión centralizada de secretos con HashiCorp Vault.
    """

    async def get_api_key(self, provider: str) -> str:
        """Obtener API key desde Vault"""
        return await self.vault.secrets.kv.v2.read_secret(
            path=f"concilio/api-keys/{provider}"
        )

    async def get_database_credentials(self, db: str) -> DBCredentials:
        """Obtener credenciales de BD con rotación automática"""
        return await self.vault.secrets.database.get_credentials(
            name=db
        )

    async def encrypt_for_agent(self, agent_id: str, data: bytes) -> bytes:
        """Encriptar datos para un agente específico"""
        key = await self.vault.secrets.transit.read_key(name=f"agent-{agent_id}")
        return await self.vault.secrets.transit.encrypt_data(
            key_name=f"agent-{agent_id}",
            plaintext=data
        )
```

### 7.3 Policy Engine

```python
@dataclass
class Policy:
    """Policy de control de acceso"""
    id: str
    name: str
    description: str

    # Condiciones
    subjects: List[str]        # Quién puede
    actions: List[str]         # Qué puede hacer
    resources: List[str]       # Sobre qué recursos
    conditions: Dict[str, Any] # Condiciones adicionales

    # Efecto
    effect: Literal["allow", "deny"]

    # Metadata
    priority: int
    created_at: float
    created_by: str

class PolicyEngine:
    """
    Motor de policies que controla cada decisión.
    """

    async def evaluate(self, context: DecisionContext) -> PolicyDecision:
        """
        Evaluar si una acción está permitida.
        Se ejecuta ANTES de cada decisión.
        """
        # Cargar policies aplicables
        policies = await self._load_policies(context)

        # Evaluar en orden de prioridad
        for policy in sorted(policies, key=lambda p: p.priority, reverse=True):
            if self._matches(policy, context):
                return PolicyDecision(
                    allowed=(policy.effect == "allow"),
                    policy_id=policy.id,
                    reason=policy.description
                )

        # Default deny
        return PolicyDecision(
            allowed=False,
            policy_id="default-deny",
            reason="No matching policy found"
        )
```

---

## 8. Capa 6: Observabilidad

### 8.1 Three Pillars

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          THREE PILLARS OF OBSERVABILITY                      │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  METRICS (Prometheus)                                                 │  │
│  │                                                                        │  │
│  │  • Request rate, latency, errors (RED)                                │  │
│  │  • Agent utilization, memory, CPU                                     │  │
│  │  • LLM token usage, cost                                              │  │
│  │  • Decision success rate                                              │  │
│  │  • Learning pipeline throughput                                       │  │
│  │                                                                        │  │
│  │  Alertas:                                                              │  │
│  │  • Error rate > 1%                                                    │  │
│  │  • Latency p99 > 5s                                                   │  │
│  │  • Cost > $50/day                                                     │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  LOGS (Loki)                                                          │  │
│  │                                                                        │  │
│  │  • Estructurados (JSON)                                               │  │
│  │  • Con trace_id, span_id                                              │  │
│  │  • Niveles: DEBUG, INFO, WARN, ERROR                                  │  │
│  │  • Retención: 30 días hot, 1 año cold                                 │  │
│  │                                                                        │  │
│  │  Tipos:                                                                │  │
│  │  • request_log: cada request/response                                 │  │
│  │  • decision_log: cada decisión tomada                                 │  │
│  │  • agent_log: actividad de agentes                                    │  │
│  │  • system_log: eventos del sistema                                    │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  TRACES (Jaeger)                                                      │  │
│  │                                                                        │  │
│  │  • Distributed tracing end-to-end                                     │  │
│  │  • Spans por cada nivel de la jerarquía                               │  │
│  │  • Latencia por componente                                            │  │
│  │  • Dependency map                                                     │  │
│  │                                                                        │  │
│  │  Ejemplo de trace:                                                     │  │
│  │  request → gateway → director → ejecutor → LLM → response             │  │
│  │         └── validation ──┘                                             │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 8.2 Structured Logging

```python
@dataclass
class LogEntry:
    """Log entry estructurado"""

    # Identificación
    timestamp: float
    trace_id: str
    span_id: str
    parent_span_id: Optional[str]

    # Contexto
    level: LogLevel
    logger: str

    # Origen
    level_hierarchy: str       # L1, L2, etc.
    entity_id: str
    domain: Optional[str]
    concilium: Optional[str]
    agent: Optional[str]

    # Evento
    event_type: str
    message: str
    data: Dict[str, Any]

    # Error handling
    error: Optional[ErrorInfo]

    # Performance
    duration_ms: Optional[float]

    def to_json(self) -> str:
        return json.dumps(asdict(self))
```

### 8.3 Dashboards

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        GRAFANA DASHBOARDS                                    │
│                                                                              │
│  Dashboard 1: System Overview                                                │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  • Request rate (QPS)                                                │    │
│  │  • Latency p50, p95, p99                                             │    │
│  │  • Error rate                                                        │    │
│  │  • Active agents por nivel                                           │    │
│  │  • Memory/CPU por servidor                                           │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  Dashboard 2: Agent Activity                                                 │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  • Agent utilization heatmap                                         │    │
│  │  • Decision success rate por dominio                                 │    │
│  │  • LLM token usage por modelo                                        │    │
│  │  • Agent-to-agent communication patterns                             │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  Dashboard 3: Learning Pipeline                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  • Experiences captured                                              │    │
│  │  • Knowledge fragments validated                                     │    │
│  │  • Learning pipeline latency                                         │    │
│  │  • Knowledge promotion rate                                          │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  Dashboard 4: Cost Management                                                │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  • Daily cost by provider                                            │    │
│  │  • Cost per domain                                                   │    │
│  │  • Token efficiency metrics                                          │    │
│  │  • Budget alerts                                                     │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 9. Capa 7: Gobernanza

### 9.1 Governance Framework

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          GOVERNANCE FRAMEWORK                                │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  POLICIES                                                             │  │
│  │                                                                        │  │
│  │  • Access Control: quién puede hacer qué                              │  │
│  │  • Data Governance: cómo se manejan los datos                         │  │
│  │  • Cost Control: límites de gasto                                     │  │
│  │  • Quality Standards: criterios de calidad                            │  │
│  │  • Compliance: regulaciones a cumplir                                 │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  CONTROLS                                                             │  │
│  │                                                                        │  │
│  │  • Rate Limiting: límites de uso                                      │  │
│  │  • Budget Controls: parar si se excede                                │  │
│  │  • Circuit Breakers: parar si hay errores                             │  │
│  │  • Approval Workflows: requiere aprobación                            │  │
│  │  • Audit Gates: validar antes de proceder                             │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  AUDIT                                                                │  │
│  │                                                                        │  │
│  │  • Decision Audit: cada decisión queda registrada                     │  │
│  │  • Access Audit: cada acceso queda registrado                         │  │
│  │  • Change Audit: cada cambio queda registrado                         │  │
│  │  • Immutable Log: no se puede modificar                               │  │
│  │  • Retention: 7 años (regulatory)                                     │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  COMPLIANCE                                                           │  │
│  │                                                                        │  │
│  │  • GDPR: derecho al olvido, portabilidad                              │  │
│  │  • SOC2: controles de seguridad                                       │  │
│  │  • ISO 27001: gestión de seguridad                                    │  │
│  │  • Internal: políticas de la organización                             │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 9.2 Decision Audit Trail

```sql
-- Schema de auditoría de decisiones
CREATE TABLE decision_audit (
    id UUID PRIMARY KEY,
    trace_id UUID NOT NULL,

    -- Contexto
    timestamp TIMESTAMPTZ NOT NULL,
    level VARCHAR(10) NOT NULL,          -- L1-L5
    domain VARCHAR(50),
    concilium_id VARCHAR(50),
    agent_id VARCHAR(50) NOT NULL,

    -- Decisión
    decision_type VARCHAR(100) NOT NULL,
    input_payload JSONB NOT NULL,
    output_payload JSONB,

    -- Validación
    validation_status VARCHAR(20),         -- approved, rejected, pending
    validator_agent VARCHAR(50),
    validation_score FLOAT,

    -- Policies
    policies_applied JSONB,
    policy_decisions JSONB,

    -- Performance
    duration_ms FLOAT,
    tokens_used INT,
    cost_usd FLOAT,

    -- Integrity
    hash VARCHAR(64) NOT NULL,             -- SHA-256 del registro
    prev_hash VARCHAR(64),                 -- Hash del registro anterior

    -- Índices
    INDEX idx_trace (trace_id),
    INDEX idx_timestamp (timestamp),
    INDEX idx_agent (agent_id),
    INDEX idx_domain (domain)
);
```

### 9.3 Change Management

```python
class ChangeManager:
    """
    Gestión de cambios con aprobación y rollback.
    """

    async def propose_change(self, change: Change) -> ChangeProposal:
        """Proponer un cambio al sistema"""
        proposal = ChangeProposal(
            id=str(uuid.uuid4()),
            change=change,
            status="pending",
            created_at=datetime.now(),
            impact_assessment=await self._assess_impact(change),
            rollback_plan=await self._create_rollback_plan(change)
        )

        # Si el cambio es de alto impacto, requiere aprobación
        if proposal.impact_assessment.level in ["high", "critical"]:
            proposal.requires_approval = True
            await self._notify_approvers(proposal)

        await self._store_proposal(proposal)
        return proposal

    async def apply_change(self, proposal_id: str) -> ChangeResult:
        """Aplicar un cambio aprobado"""
        proposal = await self._get_proposal(proposal_id)

        if proposal.status != "approved":
            raise ChangeNotApprovedError(proposal_id)

        # Crear snapshot antes del cambio
        snapshot = await self._create_snapshot()

        try:
            # Aplicar cambio
            result = await self._execute_change(proposal.change)

            # Registrar éxito
            await self._log_change_success(proposal, result)

            return ChangeResult(
                success=True,
                proposal_id=proposal_id,
                result=result
            )

        except Exception as e:
            # Rollback automático
            await self._rollback(proposal, snapshot, e)

            return ChangeResult(
                success=False,
                proposal_id=proposal_id,
                error=str(e)
            )
```

---

## 10. Flujo de Decisión Completo

### 10.1 Request Lifecycle

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          REQUEST LIFECYCLE                                   │
│                                                                              │
│  1. INGRESS                                                                  │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  • Validar autenticación                                              │  │
│  │  • Rate limiting check                                                │  │
│  │  • Crear trace_id                                                     │  │
│  │  • Log de entrada                                                     │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                    │                                         │
│                                    ▼                                         │
│  2. GOVERNANCE CHECK                                                         │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  • Evaluar policies                                                   │  │
│  │  • Verificar budget                                                   │  │
│  │  • Check compliance                                                   │  │
│  │  • Si no allowed → reject con razón                                   │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                    │                                         │
│                                    ▼                                         │
│  3. ROUTING                                                                  │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  • Determinar dominio                                                 │  │
│  │  • Resolver bindings                                                  │  │
│  │  • Identificar Catedrático responsable                               │  │
│  │  • Enviar al nivel L3 correspondiente                                 │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                    │                                         │
│                                    ▼                                         │
│  4. DOMAIN PROCESSING (L3 - Catedrático)                                     │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  • Decidir si manejar directamente o delegar                          │  │
│  │  • Si delega → enviar a Especialista (L2)                             │  │
│  │  • Log de decisión estratégica                                        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                    │                                         │
│                                    ▼                                         │
│  5. CONCILIUM PROCESSING (L2 - Tri-Agente)                                   │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  DIRECTOR:                                                            │  │
│  │  • Analizar request                                                   │  │
│  │  • Consultar RAG individual + compartido                              │  │
│  │  • Crear plan                                                         │  │
│  │  • Delegar a EJECUTOR                                                 │  │
│  │                                                                        │  │
│  │  EJECUTOR:                                                            │  │
│  │  • Ejecutar plan                                                      │  │
│  │  • Usar tools permitidas                                              │  │
│  │  • Generar artefacto                                                  │  │
│  │  • Entregar a DIRECTOR                                                │  │
│  │                                                                        │  │
│  │  ARCHIVADOR:                                                          │  │
│  │  • Validar artefacto                                                  │  │
│  │  • Verificar calidad                                                  │  │
│  │  • Actualizar memoria                                                 │  │
│  │  • Entregar validación a DIRECTOR                                     │  │
│  │                                                                        │  │
│  │  DIRECTOR:                                                            │  │
│  │  • Entregar respuesta validada                                        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                    │                                         │
│                                    ▼                                         │
│  6. LEARNING CAPTURE                                                         │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  • Capturar experiencia                                               │  │
│  │  • Enviar a learning pipeline                                         │  │
│  │  • Async processing                                                   │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                    │                                         │
│                                    ▼                                         │
│  7. EGRESS                                                                   │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  • Formatear respuesta                                                │  │
│  │  • Log de salida                                                      │  │
│  │  • Actualizar métricas                                                │  │
│  │  • Entregar al usuario                                                │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 11. Checklist de Implementación Enterprise

```
□ CAPA 1: INFRAESTRUCTURA
  □ Redis configurado con persistencia
  □ PostgreSQL con TDE habilitado
  □ LanceDB para vector storage
  □ Vault para secrets management
  □ Prometheus + Grafana + Loki para observability
  □ Tailscale para networking seguro

□ CAPA 2: ORQUESTACIÓN
  □ Fastify Gateways configurados
  □ Jerarquía de niveles implementada
  □ Interfaz unificada por nivel
  □ Bindings por dominio

□ CAPA 3: MEMORIA & CONOCIMIENTO
  □ RAG individual por agente
  □ RAG compartido por concilio
  □ RAG de dominio
  □ RAG global
  □ Learning pipeline implementado
  □ Encapsulation engine funcionando

□ CAPA 4: COMUNICACIÓN
  □ Event bus con Redis Streams
  □ Message protocol estandarizado
  □ Tracing distribuido
  □ Pipeline de comunicación

□ CAPA 5: SEGURIDAD
  □ Vault integration
  □ mTLS en comunicación interna
  □ RBAC implementado
  □ Policy engine funcionando
  □ Encriptación at-rest e in-transit

□ CAPA 6: OBSERVABILIDAD
  □ Metrics collection
  □ Structured logging
  □ Distributed tracing
  □ Dashboards configurados
  □ Alertas configuradas

□ CAPA 7: GOBERNANZA
  □ Policies definidas
  □ Controls implementados
  □ Audit log inmutable
  □ Compliance verificado
  □ Change management funcionando

□ TESTING
  □ Unit tests > 80% coverage
  □ Integration tests
  □ Load tests
  □ Security tests
  □ Chaos engineering tests

□ DOCUMENTACIÓN
  □ Arquitectura documentada
  □ Runbooks para ops
  □ API documentation
  □ Disaster recovery plan
```

---

## 12. Resumen de Tecnologías

| Categoría | Tecnología | Uso |
|-----------|------------|-----|
| **AI Gateway** | Fastify + Node.js | Multi-agente, WebSocket |
| **Message Broker** | Redis | Pub/Sub, Streams, Cache |
| **Primary DB** | PostgreSQL | Estado, auditoría |
| **Vector DB** | LanceDB | RAG, embeddings |
| **Secrets** | HashiCorp Vault | Keys, certificados |
| **Metrics** | Prometheus | Métricas |
| **Logs** | Loki | Logs estructurados |
| **Traces** | Jaeger | Distributed tracing |
| **Dashboards** | Grafana | Visualización |
| **Networking** | Tailscale | Mesh VPN |
| **Container** | Docker | Sandbox de agentes |
| **Orchestration** | PM2 | Procesos |

---

**Documento:** Arquitectura Holística OPENCLAW-system
**Ubicación:** `docs/INSTALACION-PERSONAL/11-ARQUITECTURA-HOLISTICA.md`
**Versión:** 1.0
**Fecha:** 2026-03-10
