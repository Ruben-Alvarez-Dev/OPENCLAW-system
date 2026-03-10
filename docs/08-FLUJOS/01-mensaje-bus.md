# Bus de Mensajes - Sistema de Mensajería Auditable

**ID:** DOC-FLU-BUS-001
**Versión:** 2.1.0
**Fecha:** 2026-03-09
**Nivel:** Componente Core
**Dependencias:** [Arquitectura Maestra](../01-SISTEMA/00-arquitectura-maestra.md)

---

## Resumen Ejecutivo

El Bus de Mensajes es el sistema nervioso central de OPENCLAW-system, proporcionando comunicación confiable, auditable y trazable entre todos los componentes del sistema. Todo mensaje es registrado, timestamped, y mantiene una cadena de integridad inmutable.

---

## 1. Arquitectura del Message Bus

### Visión General

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARQUITECTURA BUS DE MENSAJES                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │ PRODUCTORES  │    │   INTERMED.  │    │  CONSUMIDOR  │      │
│  │              │    │              │    │              │      │
│  │ Orquestador  │───►│              │───►│ Catedráticos │      │
│  │ Catedráticos │───►│   Cola de    │───►│ Unidades     │      │
│  │ Unidades     │───►│   Mensajes   │───►│ Subagentes   │      │
│  │ Subagentes   │───►│              │───►│ Externos     │      │
│  │ Externos     │    │              │    │              │      │
│  └──────────────┘    └──────┬───────┘    └──────────────┘      │
│                              │                                  │
│                              ▼                                  │
│                    ┌─────────────────┐                          │
│                    │  LOG AUDITORÍA │                          │
│                    │  (Solo-agregar)│                          │
│                    └─────────────────┘                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Estructura del Mensaje

### Esquema de Mensaje

```typescript
interface Message {
  // Identificación única
  id: string;                    // UUID v4

  // Timestamps
  timestamp: number;             // Unix timestamp (ms)
  created_at: string;            // ISO 8601

  // Origen y Destino
  source: MessageEndpoint;       // Quién envía
  target: MessageEndpoint;       // A quién va
  conversation_id: string;       // Para agrupar mensajes relacionados

  // Contenido
  type: MessageType;             // Tipo de mensaje
  payload: unknown;              // Datos del mensaje
  metadata: MessageMetadata;     // Metadatos adicionales

  // Integridad y Trazabilidad
  parent_id: string | null;      // ID del mensaje que originó este
  chain_hash: string;            // Hash de la cadena
  signature: string;             // Firma digital del emisor

  // Control
  priority: Priority;            // Prioridad del mensaje
  ttl: number;                   // Time-to-live en segundos
  requires_ack: boolean;         // Si requiere confirmación
  ack_timeout: number;           // Timeout para ACK (ms)
}

interface PuntoFinalMensaje {
  type: 'orquestador' | 'catedratico' | 'unidad' | 'agente' | 'subagente' | 'externo' | 'humano';
  id: string;
  domain?: string;               // Dominio si aplica
  role?: string;                 // Rol dentro del componente
}

interface MessageMetadata {
  trace_id: string;              // ID para tracing distribuido
  span_id: string;               // ID del span actual
  baggage: Record<string, string>; // Contexto propagado
  correlation_id: string;        // Para correlacionar con sistemas externos
}
```

### Tipos de Mensaje

```typescript
type MessageType =
  // Comandos (requieren acción)
  | 'command.execute'            // Ejecutar operación
  | 'command.delegate'           // Delegar tarea
  | 'command.create'             // Crear recurso
  | 'command.update'             // Actualizar recurso
  | 'command.delete'             // Eliminar recurso

  // Consultas (requieren respuesta)
  | 'query.request'              // Solicitar información
  | 'query.response'             // Responder información

  // Eventos (notificación)
  | 'event.started'              // Operación iniciada
  | 'event.completed'            // Operación completada
  | 'event.failed'               // Operación fallida
  | 'event.created'              // Recurso creado
  | 'event.updated'              // Recurso actualizado
  | 'event.deleted'              // Recurso eliminado

  // Validación
  | 'validation.request'         // Solicitar validación
  | 'validation.result'          // Resultado de validación

  // Aprobación
  | 'approval.request'           // Solicitar aprobación
  | 'approval.granted'           // Aprobación concedida
  | 'approval.denied'            // Aprobación denegada

  // Auditoría
  | 'audit.log'                  // Entrada de auditoría
  | 'audit.query'                // Consulta de auditoría

  // Sistema
  | 'system.heartbeat'           // Latido del sistema
  | 'system.error'               // Error del sistema
  | 'system.warning'             // Advertencia del sistema;
```

---

## 3. Cadena de Integridad (Chain of Custody)

### Principio

Cada mensaje está encadenado al mensaje anterior mediante un hash, creando una cadena inmutable que permite verificar la integridad de toda la comunicación.

### Implementación

```python
import hashlib
import json
from datetime import datetime
from typing import Optional

class MessageChain:
    """
    Sistema de cadena de integridad para mensajes.
    """

    def __init__(self, storage: ChainStorage):
        self.storage = storage
        self.last_hash = self.storage.get_last_hash()

    def create_message(
        self,
        source: MessageEndpoint,
        target: MessageEndpoint,
        message_type: MessageType,
        payload: dict,
        parent_id: Optional[str] = None
    ) -> Message:

        message_id = generate_uuid()
        timestamp = int(datetime.now().timestamp() * 1000)

        # Crear mensaje base
        message = {
            "id": message_id,
            "timestamp": timestamp,
            "created_at": datetime.now().isoformat(),
            "source": source,
            "target": target,
            "type": message_type,
            "payload": payload,
            "parent_id": parent_id,
            "metadata": {
                "trace_id": generate_trace_id(),
                "span_id": generate_span_id(),
                "baggage": {},
                "correlation_id": None
            }
        }

        # Calcular hash de la cadena
        chain_input = self.build_chain_input(message, self.last_hash)
        chain_hash = self.calculate_hash(chain_input)
        message["chain_hash"] = chain_hash

        # Firmar mensaje
        message["signature"] = self.sign_message(message)

        # Actualizar último hash
        self.last_hash = chain_hash

        return message

    def build_chain_input(self, message: dict, previous_hash: str) -> str:
        """Construir input para el hash de cadena"""
        chain_data = {
            "previous_hash": previous_hash,
            "message_id": message["id"],
            "timestamp": message["timestamp"],
            "source": message["source"],
            "target": message["target"],
            "type": message["type"],
            "payload_hash": self.calculate_hash(message["payload"])
        }
        return json.dumps(chain_data, sort_keys=True)

    def calculate_hash(self, data: str) -> str:
        """Calcular hash SHA-256"""
        return hashlib.sha256(data.encode()).hexdigest()

    def sign_message(self, message: dict) -> str:
        """Firmar mensaje con clave privada del emisor"""
        # En implementación real, usar criptografía asimétrica
        message_canonical = json.dumps(message, sort_keys=True)
        return self.crypto.sign(message_canonical, source_private_key)

    def verify_chain(self, messages: list[Message]) -> VerificationResult:
        """Verificar integridad de la cadena de mensajes"""
        expected_hash = GENESIS_HASH  # Hash inicial del sistema

        for i, message in enumerate(messages):
            # Reconstruir el hash esperado
            chain_input = self.build_chain_input(message, expected_hash)
            calculated_hash = self.calculate_hash(chain_input)

            # Verificar que el hash coincide
            if calculated_hash != message["chain_hash"]:
                return VerificationResult.INVALID(
                    message_index=i,
                    message_id=message["id"],
                    expected=calculated_hash,
                    actual=message["chain_hash"],
                    reason="Chain hash mismatch"
                )

            # Verificar firma
            if not self.verify_signature(message):
                return VerificationResult.INVALID(
                    message_index=i,
                    message_id=message["id"],
                    reason="Invalid signature"
                )

            expected_hash = message["chain_hash"]

        return VerificationResult.VALID(
            message_count=len(messages),
            chain_intact=True
        )
```

### Estructura de la Cadena

```
┌─────────────────────────────────────────────────────────────────┐
│                    MESSAGE CHAIN                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  GENESIS (hash: 000...000)                                      │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Message #1                                               │   │
│  │ id: a1b2c3...                                           │   │
│  │ parent_id: null                                         │   │
│  │ chain_hash: h(000...000 + a1b2c3... + payload_hash)     │   │
│  │ signature: <firma_emisor_1>                             │   │
│  └─────────────────────────────────────────────────────────┘   │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Message #2                                               │   │
│  │ id: d4e5f6...                                           │   │
│  │ parent_id: a1b2c3...                                    │   │
│  │ chain_hash: h(h1 + d4e5f6... + payload_hash)            │   │
│  │ signature: <firma_emisor_2>                             │   │
│  └─────────────────────────────────────────────────────────┘   │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Message #3                                               │   │
│  │ id: g7h8i9...                                           │   │
│  │ parent_id: d4e5f6...                                    │   │
│  │ chain_hash: h(h2 + g7h8i9... + payload_hash)            │   │
│  │ signature: <firma_emisor_3>                             │   │
│  └─────────────────────────────────────────────────────────┘   │
│       │                                                         │
│      ...                                                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Audit Log (Append-Only)

### Principio

Todos los mensajes se almacenan en un log de solo adición (append-only), garantizando inmutabilidad y permitiendo auditoría completa.

### Implementación

```python
class AuditLog:
    """
    Log de auditoría append-only e inmutable.
    """

    def __init__(self, storage_path: str):
        self.storage = WALStorage(storage_path)  # Write-Ahead Log
        self.index = MessageIndex(storage_path)

    def append(self, message: Message) -> str:
        """Añadir mensaje al log (solo adición, nunca modificación)"""

        # Verificar que no existe (idempotencia)
        if self.index.exists(message.id):
            return message.id  # Ya existe, no duplicar

        # Serializar mensaje
        entry = self.serialize_entry(message)

        # Calcular posición en el log
        position = self.storage.get_next_position()

        # Escribir al log
        self.storage.append(entry)

        # Indexar para búsqueda rápida
        self.index.index_message(message, position)

        return message.id

    def serialize_entry(self, message: Message) -> bytes:
        """Serializar entrada del log"""
        entry = {
            "position": self.storage.get_next_position(),
            "timestamp": message.timestamp,
            "message_id": message.id,
            "source": message.source,
            "target": message.target,
            "type": message.type,
            "payload": message.payload,
            "parent_id": message.parent_id,
            "chain_hash": message.chain_hash,
            "signature": message.signature,
            "raw": message.to_json()
        }
        return json.dumps(entry).encode('utf-8')

    def query(
        self,
        source: Optional[str] = None,
        target: Optional[str] = None,
        message_type: Optional[str] = None,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        conversation_id: Optional[str] = None
    ) -> list[Message]:
        """Consultar mensajes del log"""

        # Usar índices para búsqueda eficiente
        candidates = self.index.search(
            source=source,
            target=target,
            message_type=message_type,
            conversation_id=conversation_id
        )

        # Filtrar por tiempo
        if start_time or end_time:
            candidates = [
                m for m in candidates
                if self.in_time_range(m, start_time, end_time)
            ]

        # Cargar mensajes completos
        return [self.load_message(m.position) for m in candidates]

    def get_conversation(self, conversation_id: str) -> list[Message]:
        """Obtener todos los mensajes de una conversación"""
        return self.query(conversation_id=conversation_id)

    def verify_integrity(self) -> IntegrityReport:
        """Verificar integridad del log completo"""
        messages = self.get_all_messages()
        return MessageChain.verify_chain(messages)

    def export_for_audit(
        self,
        start_time: datetime,
        end_time: datetime,
        format: str = "json"
    ) -> AuditExport:
        """Exportar log para auditoría externa"""
        messages = self.query(start_time=start_time, end_time=end_time)

        export = {
            "export_metadata": {
                "generated_at": datetime.now().isoformat(),
                "start_time": start_time.isoformat(),
                "end_time": end_time.isoformat(),
                "message_count": len(messages),
                "integrity_verification": self.verify_integrity().to_dict()
            },
            "messages": [m.to_dict() for m in messages]
        }

        return AuditExport(export, format=format)
```

### Esquema de Almacenamiento

```
log_auditoria/
├── wal/
│   ├── 2026-03-01.wal        # Log write-ahead por día
│   ├── 2026-03-02.wal
│   ├── 2026-03-03.wal
│   └── ...
│
├── indice/
│   ├── por_origen/
│   │   ├── orquestador.idx
│   │   ├── jef-con.idx
│   │   ├── jef-ing.idx
│   │   └── ...
│   │
│   ├── por_destino/
│   │   ├── unidad_dev.idx
│   │   ├── unidad_infra.idx
│   │   └── ...
│   │
│   ├── por_tipo/
│   │   ├── comando.idx
│   │   ├── evento.idx
│   │   └── ...
│   │
│   ├── por_conversacion/
│   │   ├── conv-abc123.idx
│   │   └── ...
│   │
│   └── por_tiempo/
│       ├── 2026-03.idx
│       └── ...
│
└── instantaneas/
    ├── semanal/
    │   ├── 2026-S09.snap
    │   └── ...
    └── mensual/
        ├── 2026-03.snap
        └── ...
```

---

## 5. Message Broker

### Implementación

```python
from abc import ABC, abstractmethod
from typing import Callable, Any
from queue import PriorityQueue
import threading

class MessageBroker:
    """
    Broker de mensajes con soporte para colas priorizadas,
    routing, y entrega garantizada.
    """

    def __init__(self, audit_log: AuditLog):
        self.audit_log = audit_log
        self.queues: dict[str, PriorityQueue] = {}
        self.subscriptions: dict[str, list[Callable]] = {}
        self.message_chain = MessageChain(audit_log.storage)
        self.running = True

        # Iniciar workers de procesamiento
        self.dispatch_thread = threading.Thread(
            target=self._dispatch_loop,
            daemon=True
        )
        self.dispatch_thread.start()

    def publish(
        self,
        message: Message,
        ensure_delivery: bool = True
    ) -> PublishResult:
        """Publicar mensaje al broker"""

        # Registrar en cadena de integridad
        chain_message = self.message_chain.create_message(
            source=message.source,
            target=message.target,
            message_type=message.type,
            payload=message.payload,
            parent_id=message.parent_id
        )

        # Registrar en audit log
        self.audit_log.append(chain_message)

        # Encolar para entrega
        queue_name = self.get_queue_name(message.target)
        priority = self.get_priority_value(message.priority)

        self.queues.setdefault(queue_name, PriorityQueue)
        self.queues[queue_name].put((priority, chain_message))

        # Si requiere ACK, esperar confirmación
        if message.requires_ack and ensure_delivery:
            return self._wait_for_ack(chain_message)

        return PublishResult(
            success=True,
            message_id=chain_message.id,
            chain_hash=chain_message.chain_hash
        )

    def subscribe(
        self,
        endpoint: MessageEndpoint,
        handler: Callable[[Message], Any],
        message_types: Optional[list[MessageType]] = None
    ) -> Subscription:
        """Suscribirse a mensajes para un endpoint"""

        subscription_id = generate_uuid()
        queue_name = self.get_queue_name(endpoint)

        # Registrar suscripción
        if queue_name not in self.subscriptions:
            self.subscriptions[queue_name] = []

        self.subscriptions[queue_name].append({
            "id": subscription_id,
            "handler": handler,
            "message_types": message_types
        })

        return Subscription(
            id=subscription_id,
            endpoint=endpoint,
            queue_name=queue_name
        )

    def ack(self, message_id: str, status: str = "processed") -> None:
        """Confirmar procesamiento de mensaje"""
        # Registrar ACK en audit log
        ack_message = self.message_chain.create_message(
            source=MessageEndpoint(type="system", id="broker"),
            target=MessageEndpoint(type="system", id="broker"),
            message_type="system.ack",
            payload={
                "original_message_id": message_id,
                "status": status,
                "acknowledged_at": datetime.now().isoformat()
            },
            parent_id=message_id
        )
        self.audit_log.append(ack_message)

        # Notificar a quienes esperan
        self._notify_ack(message_id, status)

    def get_queue_name(self, endpoint: MessageEndpoint) -> str:
        """Obtener nombre de cola para un endpoint"""
        if endpoint.domain:
            return f"{endpoint.type}.{endpoint.domain}.{endpoint.id}"
        return f"{endpoint.type}.{endpoint.id}"

    def get_priority_value(self, priority: Priority) -> int:
        """Convertir prioridad a valor numérico (menor = más prioritario)"""
        priority_values = {
            Priority.CRITICAL: 0,
            Priority.HIGH: 1,
            Priority.NORMAL: 2,
            Priority.LOW: 3
        }
        return priority_values.get(priority, 2)

    def _dispatch_loop(self):
        """Loop de distribución de mensajes"""
        while self.running:
            for queue_name, queue in self.queues.items():
                if not queue.empty():
                    priority, message = queue.get()
                    self._deliver(queue_name, message)
                    queue.task_done()

            # Pequeña pausa para no saturar CPU
            threading.Event().wait(0.01)

    def _deliver(self, queue_name: str, message: Message):
        """Entregar mensaje a suscriptores"""
        subscribers = self.subscriptions.get(queue_name, [])

        for subscriber in subscribers:
            # Filtrar por tipo si aplica
            if subscriber["message_types"]:
                if message.type not in subscriber["message_types"]:
                    continue

            try:
                # Ejecutar handler
                result = subscriber["handler"](message)

                # Si requiere ACK, marcar como procesado
                if message.requires_ack:
                    self.ack(message.id, "processed")

            except Exception as e:
                # Registrar error
                self._handle_delivery_error(message, e)
```

---

## 6. Patrones de Comunicación

### Request-Response

```python
# Solicitud
request = message_bus.create_message(
    source=MessageEndpoint(type="unit", id="dev_unit", domain="dev"),
    target=MessageEndpoint(type="unit", id="infra_unit", domain="infra"),
    message_type="query.request",
    payload={
        "query": "server_status",
        "server_id": "prod-01"
    },
    requires_ack=True,
    ack_timeout=30000  # 30 segundos
)

response_future = message_bus.publish(request)
response = response_future.get(timeout=30)

# Respuesta
response_msg = message_bus.create_message(
    source=MessageEndpoint(type="unit", id="infra_unit", domain="infra"),
    target=MessageEndpoint(type="unit", id="dev_unit", domain="dev"),
    message_type="query.response",
    payload={
        "server_status": "healthy",
        "metrics": {...}
    },
    parent_id=request.id  # Referencia a la solicitud
)
```

### Pub/Sub (Eventos)

```python
# Publicar evento
event = message_bus.create_message(
    source=MessageEndpoint(type="unit", id="dev_unit", domain="dev"),
    target=MessageEndpoint(type="chief", id="all"),  # Broadcast
    message_type="event.completed",
    payload={
        "task_id": "task-123",
        "result": {...}
    }
)
message_bus.publish(event)

# Suscribirse a eventos
def handle_completion_event(message: Message):
    print(f"Task completed: {message.payload['task_id']}")

message_bus.subscribe(
    endpoint=MessageEndpoint(type="chief", id="CEngO"),
    handler=handle_completion_event,
    message_types=["event.completed"]
)
```

### Command Pattern

```python
# Enviar comando
command = message_bus.create_message(
    source=MessageEndpoint(type="human", id="user@example.com"),
    target=MessageEndpoint(type="unit", id="dev_unit", domain="dev"),
    message_type="command.execute",
    payload={
        "operation": "deploy",
        "environment": "staging",
        "service": "api-gateway"
    },
    priority=Priority.HIGH,
    requires_ack=True
)
message_bus.publish(command)
```

---

## 7. Trazabilidad y Auditoría

### Trace ID Propagation

```python
class TracingMiddleware:
    """
    Middleware para propagar trace IDs a través del sistema.
    """

    def process_outgoing(self, message: Message) -> Message:
        # Generar o propagar trace ID
        if not message.metadata.get("trace_id"):
            message.metadata["trace_id"] = generate_trace_id()

        # Generar nuevo span ID para este hop
        message.metadata["span_id"] = generate_span_id()

        # Propagar baggage
        # (contexto adicional que viaja con el mensaje)
        if current_context.baggage:
            message.metadata["baggage"].update(current_context.baggage)

        return message

    def process_incoming(self, message: Message):
        # Establecer contexto de tracing
        current_context.trace_id = message.metadata["trace_id"]
        current_context.span_id = message.metadata["span_id"]
        current_context.baggage = message.metadata.get("baggage", {})
        current_context.parent_span_id = message.metadata.get("span_id")
```

### Distributed Tracing

```python
class DistributedTracer:
    """
    Sistema de tracing distribuido para visualizar flujos de mensajes.
    """

    def trace_conversation(self, conversation_id: str) -> TraceGraph:
        """Obtener grafo de traceo para una conversación"""
        messages = self.audit_log.get_conversation(conversation_id)

        # Construir grafo
        graph = TraceGraph()

        for msg in messages:
            graph.add_node(
                id=msg.id,
                type=msg.type,
                source=msg.source,
                target=msg.target,
                timestamp=msg.timestamp
            )

            if msg.parent_id:
                graph.add_edge(msg.parent_id, msg.id)

        return graph

    def trace_message_flow(self, message_id: str) -> MessageFlow:
        """Trazar flujo completo desde un mensaje"""
        # Obtener mensaje
        message = self.audit_log.get_message(message_id)

        # Obtener ancestros
        ancestors = self.get_ancestors(message)

        # Obtener descendientes
        descendants = self.get_descendants(message)

        return MessageFlow(
            root=ancestors[0] if ancestors else message,
            target=message,
            ancestors=ancestors,
            descendants=descendants,
            total_messages=1 + len(ancestors) + len(descendants)
        )

    def generate_trace_report(
        self,
        conversation_id: str,
        format: str = "mermaid"
    ) -> str:
        """Generar reporte visual del traceo"""

        graph = self.trace_conversation(conversation_id)

        if format == "mermaid":
            return self.to_mermaid(graph)
        elif format == "json":
            return self.to_json(graph)
        elif format == "dot":
            return self.to_dot(graph)
```

### Consultas de Auditoría

```python
class AuditQuery:
    """
    Consultas de auditoría sobre el message log.
    """

    def __init__(self, audit_log: AuditLog):
        self.audit_log = audit_log

    def find_all_from(
        self,
        source: str,
        time_range: tuple[datetime, datetime]
    ) -> list[Message]:
        """Encontrar todos los mensajes de un origen"""
        return self.audit_log.query(
            source=source,
            start_time=time_range[0],
            end_time=time_range[1]
        )

    def find_all_to(
        self,
        target: str,
        time_range: tuple[datetime, datetime]
    ) -> list[Message]:
        """Encontrar todos los mensajes a un destino"""
        return self.audit_log.query(
            target=target,
            start_time=time_range[0],
            end_time=time_range[1]
        )

    def find_commands(
        self,
        time_range: tuple[datetime, datetime]
    ) -> list[Message]:
        """Encontrar todos los comandos ejecutados"""
        return self.audit_log.query(
            message_type="command.*",
            start_time=time_range[0],
            end_time=time_range[1]
        )

    def find_approvals(
        self,
        time_range: tuple[datetime, datetime]
    ) -> list[Message]:
        """Encontrar todas las aprobaciones"""
        messages = []
        for msg_type in ["approval.request", "approval.granted", "approval.denied"]:
            messages.extend(self.audit_log.query(
                message_type=msg_type,
                start_time=time_range[0],
                end_time=time_range[1]
            ))
        return messages

    def find_human_interventions(
        self,
        time_range: tuple[datetime, datetime]
    ) -> list[Message]:
        """Encontrar todas las intervenciones humanas"""
        return self.audit_log.query(
            source="human",
            start_time=time_range[0],
            end_time=time_range[1]
        )

    def calculate_metrics(
        self,
        time_range: tuple[datetime, datetime]
    ) -> AuditMetrics:
        """Calcular métricas de comunicación"""
        all_messages = self.audit_log.query(
            start_time=time_range[0],
            end_time=time_range[1]
        )

        return AuditMetrics(
            total_messages=len(all_messages),
            by_type=self.count_by_type(all_messages),
            by_source=self.count_by_source(all_messages),
            by_target=self.count_by_target(all_messages),
            avg_response_time=self.calculate_avg_response_time(all_messages),
            error_rate=self.calculate_error_rate(all_messages)
        )
```

---

## 8. Configuración

### Archivo de Configuración

```yaml
# config/message_bus.yaml

message_bus:
  broker:
    type: "internal"  # internal, redis, rabbitmq, nats
    max_queue_size: 10000
    worker_threads: 4

  delivery:
    retry_attempts: 3
    retry_delay_ms: 1000
    dead_letter_queue: true
    ack_timeout_ms: 30000

  audit:
    enabled: true
    storage_path: "/data/audit_log"
    wal_rotation: "daily"
    index_all_fields: true
    retention_days: 365

  integrity:
    chain_enabled: true
    signing_enabled: true
    hash_algorithm: "sha256"
    verify_on_read: true

  tracing:
    enabled: true
    sample_rate: 1.0  # 100% de mensajes
    export_formats: ["mermaid", "json", "dot"]

  priorities:
    critical: 0
    high: 1
    normal: 2
    low: 3

  message_types:
    require_ack:
      - "command.*"
      - "approval.request"
      - "validation.request"
    log_payload:
      - "*"
    redact_fields:
      - "password"
      - "token"
      - "secret"
```

---

## 9. API Reference

### MessageBus API

```python
class MessageBusAPI:
    """
    API pública del Message Bus.
    """

    def publish(
        self,
        target: MessageEndpoint,
        message_type: MessageType,
        payload: dict,
        priority: Priority = Priority.NORMAL,
        requires_ack: bool = False,
        parent_id: Optional[str] = None
    ) -> PublishResult:
        """Publicar mensaje"""
        pass

    def subscribe(
        self,
        handler: Callable[[Message], Any],
        message_types: Optional[list[MessageType]] = None
    ) -> Subscription:
        """Suscribirse a mensajes"""
        pass

    def unsubscribe(self, subscription: Subscription) -> None:
        """Cancelar suscripción"""
        pass

    def request(
        self,
        target: MessageEndpoint,
        query: dict,
        timeout_ms: int = 30000
    ) -> Message:
        """Solicitud síncrona con respuesta"""
        pass

    def ack(self, message_id: str, status: str = "processed") -> None:
        """Confirmar procesamiento"""
        pass

    def get_audit_log(self) -> AuditLog:
        """Obtener referencia al audit log"""
        pass

    def trace_conversation(self, conversation_id: str) -> TraceGraph:
        """Trazar conversación"""
        pass

    def verify_integrity(self) -> IntegrityReport:
        """Verificar integridad del sistema de mensajes"""
        pass
```

---

## 10. Métricas

| Métrica | Target | Descripción |
|---------|--------|-------------|
| **Message Throughput** | > 1000 msg/s | Mensajes procesados por segundo |
| **Avg Latency** | < 10ms | Latencia promedio de entrega |
| **Delivery Rate** | 99.99% | % de mensajes entregados |
| **Audit Completeness** | 100% | % de mensajes en audit log |
| **Integrity Verification** | 100% | % de cadena verificada |
| **Query Response Time** | < 100ms | Tiempo de respuesta de consultas |

---

## Referencias

- [Arquitectura Maestra](../01-SISTEMA/00-arquitectura-maestra.md)
- [Protocolos de Validación](02-validacion.md)
- [Arquitectura de Memoria](../09-MEMORIA/00-arquitectura-memoria.md)

---

**Documento:** Bus de Mensajes - Sistema de Mensajería Auditable
**Ubicación:** `docs/08-FLUJOS/01-mensaje-bus.md`
**Versión:** 2.1.0
**Fecha:** 2026-03-09
