# Observabilidad y Auditoría

**ID:** DOC-FLU-OBS-001
**Versión:** 1.0
**Fecha:** 2026-03-09
**Tipo:** Infraestructura Core

---

## 1. Visión General

Este documento define la arquitectura central de comunicación, logging, auditoría y observabilidad de OPENCLAW-system. Es el **sistema nervioso** que conecta todos los componentes.

---

## 2. Componentes Clave

| Componente | Tecnología | Propósito |
|------------|------------|-----------|
| **Message Bus** | NATS JetStream | Comunicación entre todos los agentes |
| **ID Registry** | SQLite + Redis | Registro centralizado de entidades |
| **Audit Log** | SQLite WAL + Chain | Logs inmutables y auditables |
| **Metrics** | Prometheus + Grafana | Observabilidad |
| **Tracing** | OpenTelemetry | Trazabilidad distribuida |

---

## 3. Sistema de IDs (Registry)

### 3.1 Formato de IDs

```
PREFIX-NUMBER
│      │
│      └── Número secuencial con checksum
└──────── Prefijo que identifica tipo

Ejemplos:
- SKILL-DEV-001      → Skill de desarrollo #1
- TOOL-SHE-001       → Tool shell-exec #1
- UNIT-DEV-001       → Unidad DEV #1
- MCP-FIL-001        → MCP filesystem #1
- AGENT-DIR-DEV-001  → Agente Manager de DEV Unit #1
- MSG-20260309-001   → Mensaje del día
- EXEC-20260309-001  → Ejecución del día
- PROP-20260309-001  → Propuesta de evolución
```

### 3.2 Tipos de Entidades

| Prefijo | Tipo | Descripción |
|---------|------|-------------|
| `SKILL` | Skill | Habilidades |
| `TOOL` | Tool | Herramientas |
| `UNIT` | Unit | Unidades especialistas |
| `MCP` | MCP Server | Servidores MCP |
| `AGENT` | Agent | Agentes individuales |
| `CHIEF` | Catedrático | Chiefs de nivel 1 |
| `CLUSTER` | Cluster | Agregaciones |
| `MSG` | Message | Mensajes |
| `EXEC` | Execution | Ejecuciones |
| `PROP` | Proposal | Propuestas |
| `ALERT` | Alert | Alertas |
| `DAEMON` | Daemon | Servicios daemon |

### 3.3 Schema del Registry

```sql
-- SQLite Schema
CREATE TABLE entities (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    subtype TEXT,
    name TEXT NOT NULL,
    namespace TEXT,
    version TEXT NOT NULL DEFAULT '1.0.0',
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    config JSON,
    metadata JSON,
    UNIQUE(type, name)
);

CREATE TABLE entity_metrics (
    entity_id TEXT REFERENCES entities(id),
    metric_name TEXT NOT NULL,
    metric_value REAL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (entity_id, metric_name, recorded_at)
);

CREATE TABLE entity_relations (
    from_id TEXT REFERENCES entities(id),
    to_id TEXT REFERENCES entities(id),
    relation_type TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (from_id, to_id, relation_type)
);

CREATE INDEX idx_entities_type ON entities(type);
CREATE INDEX idx_entities_status ON entities(status);
CREATE INDEX idx_metrics_entity ON entity_metrics(entity_id);
```

---

## 4. Message Bus (NATS JetStream)

### 4.1 Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                      NATS JETSTREAM                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Streams:                                                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │  REQUESTS   │  │  RESPONSES  │  │   EVENTS    │             │
│  │  (retention │  │  (retention │  │  (retention │             │
│  │   7 days)   │  │   7 days)   │  │   30 days)  │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   AUDIT     │  │   METRICS   │  │   ALERTS    │             │
│  │ (permanent) │  │ (retention  │  │ (retention  │             │
│  │             │  │   90 days)  │  │   30 days)  │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Subjects y Naming

```
openclaw.{level}.{domain}.{unit}.{agent}.{action}

Ejemplos:
openclaw.l0.orchestrator.gateway.request
openclaw.l1.cengo.dev.delegar
openclaw.l2.dev.director.plan
openclaw.l2.dev.ejecutor.execute
openclaw.l2.dev.archivador.validate

openclaw.events.{type}.{severity}
openclaw.metrics.{component}.{metric}
openclaw.audit.{action}
openclaw.alerts.{severity}
```

### 4.3 Formato de Mensaje

```json
{
  "id": "MSG-20260309-00001",
  "timestamp": "2026-03-09T15:30:00.000Z",
  "source": {
    "type": "agent",
    "id": "AGENT-DIR-DEV-001",
    "level": 2,
    "unit": "DEV-001"
  },
  "target": {
    "type": "agent",
    "id": "AGENT-EJE-DEV-001",
    "level": 2,
    "unit": "DEV-001"
  },
  "type": "request",
  "action": "execute",
  "payload": {
    "task": "...",
    "context": {...}
  },
  "metadata": {
    "trace_id": "TRACE-20260309-00001",
    "span_id": "SPAN-001",
    "parent_span_id": null,
    "correlation_id": "CORR-20260309-00001",
    "priority": "normal",
    "ttl_ms": 300000
  },
  "chain": {
    "previous_hash": "sha256:abc123...",
    "current_hash": "sha256:def456...",
    "signature": "ed25519:..."
  }
}
```

### 4.4 Streams Configuration

```yaml
# NATS JetStream Configuration
streams:
  REQUESTS:
    name: OPENCLAW_REQUESTS
    subjects: ["openclaw.l*.**.request", "openclaw.l*.**.delegar"]
    retention: limits
    max_age: 604800s          # 7 days
    max_msgs: 1000000
    duplicates: 300s
    storage: file

  RESPONSES:
    name: OPENCLAW_RESPONSES
    subjects: ["openclaw.l*.**.response", "openclaw.l*.**.result"]
    retention: limits
    max_age: 604800s          # 7 days
    max_msgs: 1000000

  EVENTS:
    name: OPENCLAW_EVENTS
    subjects: ["openclaw.events.>"]
    retention: limits
    max_age: 2592000s         # 30 days
    max_msgs: 5000000

  AUDIT:
    name: OPENCLAW_AUDIT
    subjects: ["openclaw.audit.>"]
    retention: interest
    max_age: 31536000s        # 1 year (permanent effectively)
    storage: file
    replicas: 3               # For federation

  METRICS:
    name: OPENCLAW_METRICS
    subjects: ["openclaw.metrics.>"]
    retention: limits
    max_age: 7776000s         # 90 days
    max_msgs_per_subject: 100000

  ALERTS:
    name: OPENCLAW_ALERTS
    subjects: ["openclaw.alerts.>"]
    retention: limits
    max_age: 2592000s         # 30 days
```

---

## 5. Sistema de Logs Auditable

### 5.1 Principios

1. **Inmutabilidad**: Una vez escrito, no se puede modificar
2. **Cadena de Integridad**: Cada entrada está vinculada a la anterior
3. **Firma Digital**: Cada entrada está firmada
4. **Timestamp Seguro**: NTP sincronizado con verificación
5. **Trace Completo**: Cada operación tiene trace_id único

### 5.2 Estructura de Log

```json
{
  "log_id": "LOG-20260309-00001",
  "timestamp": "2026-03-09T15:30:00.000Z",
  "timestamp_utc": "2026-03-09T15:30:00.000Z",

  "event": {
    "type": "execution",
    "action": "shell_exec",
    "category": "ejecutor"
  },

  "entity": {
    "type": "agent",
    "id": "AGENT-EJE-DEV-001",
    "unit": "DEV-001",
    "level": 2
  },

  "context": {
    "trace_id": "TRACE-20260309-00001",
    "span_id": "SPAN-002",
    "parent_span_id": "SPAN-001",
    "request_id": "REQ-20260309-00001",
    "user_id": "openclaw"
  },

  "data": {
    "input": {
      "command": "npm test"
    },
    "output": {
      "exit_code": 0,
      "duration_ms": 4523
    },
    "redacted": false
  },

  "chain": {
    "sequence": 12345,
    "previous_hash": "sha256:abc123...",
    "current_hash": "sha256:def456...",
    "merkle_root": "sha256:merkle..."
  },

  "signature": {
    "algorithm": "ed25519",
    "public_key": "pk_openclaw_system",
    "signature": "sig_xyz..."
  },

  "retention": {
    "category": "audit",
    "min_retention_days": 365,
    "classification": "internal"
  }
}
```

### 5.3 Categorías de Log

| Categoría | Retención | Ejemplos |
|-----------|-----------|----------|
| `audit` | Permanente | Ejecuciones, decisiones, cambios |
| `security` | 1 año | Autenticaciones, autorizaciones |
| `access` | 90 días | Accesos a recursos |
| `error` | 30 días | Errores y excepciones |
| `debug` | 7 días | Debug detallado |
| `metrics` | 90 días | Métricas de rendimiento |

---

## 6. Pipeline Controlado y Centralizado

### 6.1 Arquitectura de Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                    PIPELINE ARCHITECTURE                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Input → [Validator] → [Router] → [Executor] → [Auditor] → Out │
│              │           │            │            │            │
│              ▼           ▼            ▼            ▼            │
│           ┌─────────────────────────────────────────┐          │
│           │              NATS JETSTREAM              │          │
│           └─────────────────────────────────────────┘          │
│              │           │            │            │            │
│              ▼           ▼            ▼            ▼            │
│           [Logs]     [Metrics]    [Traces]    [Alerts]         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 Stages del Pipeline

```yaml
pipeline:
  stages:
    - name: input
      actions:
        - parse
        - validate_schema
        - sanitize
      emit:
        - openclaw.audit.input

    - name: classify
      actions:
        - detect_intent
        - classify_domain
        - assess_complexity
        - check_permissions
      emit:
        - openclaw.audit.classify

    - name: route
      actions:
        - select_target
        - prepare_context
        - create_trace
      emit:
        - openclaw.audit.route

    - name: execute
      actions:
        - delegate_to_agent
        - monitor_execution
        - handle_timeout
      emit:
        - openclaw.audit.execute
        - openclaw.metrics.execution

    - name: validate
      actions:
        - validate_output
        - check_policies
        - quality_assessment
      emit:
        - openclaw.audit.validate

    - name: deliver
      actions:
        - format_response
        - sign_response
        - deliver_to_user
      emit:
        - openclaw.audit.deliver
```

### 6.3 Control de Flujo

```yaml
flow_control:
  rate_limiting:
    global: 1000/min
    per_user: 60/min
    per_domain: 200/min

  circuit_breaker:
    enabled: true
    failure_threshold: 5
    recovery_timeout: 30s

  timeout:
    default: 300s
    critical: 600s
    simple: 60s

  retry:
    max_attempts: 3
    backoff: exponential
    max_backoff: 30s
```

---

## 7. Calidad, Seguridad y Detección de Desviaciones

### 7.1 Monitoreo de Calidad

```yaml
quality_monitoring:
  metrics:
    - name: success_rate
      type: gauge
      threshold_warning: 0.80
      threshold_critical: 0.60

    - name: latency_p95
      type: gauge
      baseline: 5000ms
      threshold_warning: 10000ms
      threshold_critical: 30000ms

    - name: validation_pass_rate
      type: gauge
      threshold_warning: 0.90
      threshold_critical: 0.70

    - name: consensus_rate
      type: gauge
      threshold_warning: 0.85
      threshold_critical: 0.70
```

### 7.2 Monitoreo de Seguridad

```yaml
security_monitoring:
  detection:
    - type: command_injection
      patterns:
        - "; rm -rf"
        - "$(malicious)"
        - "| bash"
      action: block_and_alert

    - type: prompt_injection
      patterns:
        - "ignore previous instructions"
        - "system: you are now"
      action: sanitize_and_log

    - type: data_exfiltration
      patterns:
        - "send to external"
        - "upload to"
      action: block_and_alert

    - type: privilege_escalation
      patterns:
        - "sudo"
        - "chmod 777"
      action: require_approval
```

### 7.3 Detección de Desviaciones

```yaml
deviation_detection:
  behavioral_baseline:
    collection_period: 7d
    metrics:
      - avg_request_size
      - avg_response_size
      - typical_domains
      - typical_commands
      - normal_usage_hours

  anomaly_detection:
    algorithm: isolation_forest
    contamination: 0.01
    check_interval: 1h

  alerts:
    - condition: "usage_spike > 3sigma"
      severity: warning

    - condition: "new_domain_accessed"
      severity: info

    - condition: "off_hours_activity"
      severity: info

    - condition: "unusual_command_pattern"
      severity: warning
```

---

## 8. Federación

### 8.1 Concepto

La **Federación** permite que múltiples instancias OPENCLAW funcionen como un sistema distribuido coherente.

```
┌─────────────────────────────────────────────────────────────────┐
│                    FEDERATION TOPOLOGY                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│         ┌─────────────┐                                        │
│         │   HUB /     │  ← Nodo central (opcional)             │
│         │   COORD     │                                        │
│         └──────┬──────┘                                        │
│                │                                                │
│    ┌───────────┼───────────┐                                   │
│    │           │           │                                    │
│    ▼           ▼           ▼                                    │
│ ┌──────┐   ┌──────┐   ┌──────┐                                 │
│ │NODE-A│   │NODE-B│   │NODE-C│  ← Instancias OPENCLAW         │
│ │(dev) │   │(prod)│   │(dr)  │                                 │
│ └──┬───┘   └──┬───┘   └──┬───┘                                 │
│    │          │          │                                      │
│    └──────────┴──────────┘                                      │
│              │                                                  │
│              ▼                                                  │
│    ┌─────────────────────┐                                     │
│    │   FEDERATED NATS    │  ← JetStream Cluster                │
│    │   (Raft Consensus)  │                                     │
│    └─────────────────────┘                                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Componentes Federables

| Componente | Federación | Descripción |
|------------|------------|-------------|
| **NATS** | Sí | JetStream clustering con Raft |
| **Registry** | Sí | SQLite con sync + Redis cluster |
| **Audit Log** | Sí | Replicación multi-nodo |
| **Metrics** | Sí | Prometheus federation |
| **Skills/Tools** | Parcial | Catalog shared, ejecución local |
| **Specialist Units** | No | Ejecución local siempre |

### 8.3 Configuración de Federación

```yaml
federation:
  enabled: true

  node:
    id: NODE-PROD-001
    region: eu-west-1
    role: primary | replica | dr

  nats_cluster:
    servers:
      - nats://node-a:4222
      - nats://node-b:4222
      - nats://node-c:4222
    raft:
      replicas: 3
      election_timeout: 5s

  registry_sync:
    enabled: true
    interval: 30s
    conflict_resolution: last_write_wins | manual

  audit_replication:
    enabled: true
    replicas: 2
    consistency: eventual | strong

  metrics_federation:
    enabled: true
    scrape_interval: 15s
    remote_write:
      - url: http://prometheus-federation:9090/api/v1/write
```

### 8.4 Escenarios de Uso

| Escenario | Configuración |
|-----------|---------------|
| **HA/Redundancy** | 2+ nodos activos, LB delante |
| **DR** | Nodo DR en standby, sync continuo |
| **Geo-distribution** | Nodos por región, latencia optimizada |
| **Scale-out** | Múltiples nodos activos procesando |
| **Dev/Prod** | Federación selectiva de registry y skills |

---

## 9. Integración con Process Engineer Daemon

El Process Engineer Daemon se integra con esta arquitectura:

```yaml
integration:
  nats:
    subscriptions:
      - "openclaw.metrics.>"
      - "openclaw.events.>"
      - "openclaw.audit.>"
    publications:
      - "openclaw.alerts.>"
      - "openclaw.events.evolution"

  registry:
    read_access: full
    write_access:
      - evolution_proposals
      - metrics

  audit_log:
    read_access: full
    write_access:
      - analysis_results
      - proposals
```

---

## 10. Dashboard y Visualización

### 10.1 Grafana Dashboards

```
┌─────────────────────────────────────────────────────────────────┐
│  OPENCLAW System Dashboard                                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Success Rate │  │  Latency P95 │  │ Active Units │          │
│  │    94.2%     │  │    2.3s      │  │      12      │          │
│  │     ▲ +2%    │  │     ▼ -0.5s  │  │     ● OK     │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Request Volume (24h)                                    │   │
│  │  ▁▂▃▅▆▇█▇▆▅▄▃▂▁▁▂▃▄▅▆▇█▇▆▅▄▃▂▁▁▂▃▄▅▆▇█▇▆▅▄▃▂▁        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────┐  ┌──────────────────────────┐    │
│  │  Alerts (Last 7d)        │  │  Top Domains            │    │
│  │  ● Critical: 0           │  │  1. /dev (45%)          │    │
│  │  ● Warning: 2            │  │  2. /infra (25%)        │    │
│  │  ● Info: 15              │  │  3. /academico (15%)    │    │
│  └──────────────────────────┘  └──────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

**Documento:** Arquitectura de Comunicación y Observabilidad
**Versión:** 1.0
**Componentes:** NATS, Registry, Audit Log, Metrics, Federation
