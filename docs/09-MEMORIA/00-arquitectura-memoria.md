# Arquitectura de Memoria

**ID:** DOC-MEM-ARC-001
**Versión:** 2.1.0
**Fecha:** 2026-03-09
**Nivel:** Componente Core
**Dependencias:** [Arquitectura Maestra](../01-SISTEMA/00-arquitectura-maestra.md)

---

## Resumen

El sistema OPENCLAW implementa 4 tipos de memoria jerárquica para mantener contexto, aprender de experiencias y persistir conocimiento. Cada nivel de memoria tiene un scope, propósito y mecanismo de almacenamiento diferente.

---

## 1. Los 4 Tipos de Memoria

```
┌─────────────────────────────────────────────────────────────────┐
│                    MEMORIA GLOBAL                               │
│                    ─────────────────                           │
│  Scope: Sistema completo                                        │
│  Contenido: Decisiones arquitectónicas, lecciones globales     │
│  Storage: Central knowledge library                             │
│  Acceso: Todos los agentes (lectura)                           │
│           Orchestrator (escritura)                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    MEMORIA DE DOMINIO                           │
│                    ──────────────────                          │
│  Scope: Un dominio específico (/dev, /infra, etc.)             │
│  Contenido: Conocimiento del dominio, procedimientos           │
│  Storage: Domain knowledge base                                 │
│  Acceso: Todos los especialistas del dominio                   │
│           Domain Chief (escritura aprobada)                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    MEMORIA DE UNIDAD                            │
│                    ──────────────────                          │
│  Scope: Una unidad tri-agente (Director + Ejecutor + Archivador)  │
│  Contenido: Colaboración interna, contexto compartido          │
│  Storage: Unit-level storage                                    │
│  Acceso: Solo los 3 agentes de la unidad                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    MEMORIA DE AGENTE                            │
│                    ──────────────────                          │
│  Scope: Un agente individual                                    │
│  Contenido: Contexto personal, decisiones propias              │
│  Storage: Vector DB individual                                  │
│  Acceso: Solo el agente                                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Comparativa de Memorias

| Aspecto | Agente | Unidad | Dominio | Global |
|---------|--------|--------|---------|--------|
| **Scope** | Individual | Tri-agente | Todo /dev, /infra... | Sistema completo |
| **Ejemplo** | Ejecutor de DES | Unidad DES | Dominio /dev | OPENCLAW-system |
| **Contenido** | Decisiones propias | Colaboración D/E/A | Procedimientos /dev | Arquitectura sistema |
| **Storage** | BD Vector agente | Almacen unidad | BC Dominio | Biblioteca central |
| **Lectura** | Solo agente | Solo unidad | Especialistas dominio | Todos |
| **Escritura** | Solo agente | Archivador | Catedrático aprobado | Orquestador |

---

## 3. Estructura de Directorios

```
memory/
│
├── global/                          # Memoria Global
│   ├── architecture_decisions/      # ADRs
│   ├── lessons_learned/             # Lecciones globales
│   ├── system_configuration/        # Config del sistema
│   └── knowledge_library/           # Biblioteca central
│
├── domains/                         # Memoria por Dominio
│   ├── dev/
│   │   ├── procedures/              # Procedimientos dev
│   │   ├── code_patterns/           # Patrones de código
│   │   └── solutions/               # Soluciones probadas
│   │
│   ├── infra/
│   │   ├── configurations/          # Configs de servidores
│   │   ├── playbooks/               # Ansible/playbooks
│   │   └── incidents/               # Registro de incidentes
│   │
│   ├── hosteleria/
│   │   ├── recipes/                 # Recetas
│   │   ├── procedures/              # Procedimientos F&B
│   │   └── standards/               # Estándares de calidad
│   │
│   └── fitness/
│       ├── programs/                # Programas de entrenamiento
│       ├── techniques/              # Técnicas deportivas
│       └── nutrition/               # Guías nutricionales
│
├── units/                           # Memoria por Unidad
│   ├── dev_unit/
│   │   ├── shared_context/          # Contexto compartido
│   │   ├── sessions/                # Sesiones de trabajo
│   │   └── validations/             # Validaciones realizadas
│   │
│   ├── infra_unit/
│   └── research_unit/
│
└── agents/                          # Memoria por Agente
    ├── orchestrator_director/
    ├── orchestrator_ejecutor/
    ├── orchestrator_archivador/
    │
    ├── dev_director/
    ├── dev_ejecutor/
    ├── dev_archivador/
    │
    └── ... (demás agentes)
```

---

## 4. Memoria de Agente

### Propósito

Mantener contexto individual de cada agente, incluyendo:
- Historial de decisiones propias
- Preferencias aprendidas
- Estado interno
- Contexto de conversación

### Implementación

```typescript
// src/memory/agent-memory.ts
import { VectorStoreRetriever } from './vector-store';
import { ConversationBuffer } from './conversation-buffer';

interface MemoryDocument {
  pageContent: string;
  metadata: {
    key: string;
    agent: string;
    timestamp: string;
    [key: string]: unknown;
  };
}

export class AgentMemory {
  private agentId: string;
  private storage: VectorStoreRetriever;
  private shortTerm: ConversationBuffer;
  private longTerm: VectorStoreRetriever;

  constructor(agentId: string, storageBackend: 'sqlite' | 'lancedb' = 'sqlite') {
    this.agentId = agentId;
    this.storage = new VectorStoreRetriever(`memory/agents/${agentId}/`);
    this.shortTerm = new ConversationBuffer();
    this.longTerm = new VectorStoreRetriever(this.storage);
  }

  /**
   * Guardar en memoria a largo plazo
   */
  async remember(key: string, value: string, metadata?: Record<string, unknown>): Promise<void> {
    const doc: MemoryDocument = {
      pageContent: value,
      metadata: {
        key,
        agent: this.agentId,
        timestamp: new Date().toISOString(),
        ...(metadata ?? {})
      }
    };

    await this.longTerm.addDocuments([doc]);
  }

  /**
   * Recuperar de memoria a largo plazo
   */
  async recall(query: string, k: number = 5): Promise<MemoryDocument[]> {
    return this.longTerm.getRelevantDocuments(query, k);
  }

  /**
   * Añadir a memoria a corto plazo
   */
  addToConversation(role: 'user' | 'assistant' | 'system', content: string): void {
    this.shortTerm.addMessage(role, content);
  }

  /**
   * Obtener contexto de conversación actual
   */
  getContextWindow(): string {
    return this.shortTerm.getBuffer();
  }
}
```

### Ejemplo de Uso

```python
# En el Ejecutor de DEV Unit
ejecutor_memory = AgentMemory("dev_ejecutor")

# Guardar decisión
ejecutor_memory.remember(
    key="api_design_decision",
    value="Decidido usar REST sobre GraphQL para simplicidad",
    metadata={"project": "openclaw-api", "domain": "dev"}
)

# Recuperar contexto
context = ejecutor_memory.recall("diseño API anterior")
```

---

## 5. Memoria de Unidad

### Propósito

Compartir contexto entre los 3 agentes de una unidad tri-agente:
- Director puede ver lo que Ejecutor ejecutó
- Archivador puede acceder a todo para validar
- Ejecutor puede ver planes del Director

### Implementación

```python
class UnitMemory:
    def __init__(self, unit_id: str):
        self.unit_id = unit_id
        self.shared_storage = SharedStorage(f"memory/units/{unit_id}/")
        self.message_log = MessageLog()

    def share(self, from_agent: str, to_agents: list, content: dict):
        """Compartir información dentro de la unidad"""
        self.shared_storage.write({
            "from": from_agent,
            "to": to_agents,
            "content": content,
            "timestamp": datetime.now().isoformat()
        })

        for agent in to_agents:
            self.message_log.notify(agent, content)

    def get_shared_context(self, agent: str) -> list:
        """Obtener contexto compartido para un agente"""
        return self.shared_storage.read_for_agent(agent)
```

### Flujo de Compartición

```
┌─────────────────────────────────────────────────────────────┐
│                    DEV UNIT MEMORY                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Director ──────► Escribe plan                            │
│       │                                                     │
│       ▼                                                     │
│  Almac. Compartido ◄── Ejecutor lee plan                   │
│       │                                                     │
│       ▼                                                     │
│  Ejecutor ────────► Escribe resultados                     │
│       │                                                     │
│       ▼                                                     │
│  Almac. Compartido ◄── Archivador lee para validar         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. Memoria de Dominio

### Propósito

Compartir conocimiento entre todas las unidades de un dominio:
- Procedimientos estándar
- Soluciones probadas
- Lecciones aprendidas del dominio

### Implementación

```python
class DomainMemory:
    def __init__(self, namespace: str):
        self.namespace = namespace
        self.kb = KnowledgeBase(f"memory/domains/{namespace}/")
        self.procedures = ProcedureRegistry(namespace)
        self.solutions = SolutionLibrary(namespace)

    def add_procedure(self, name: str, steps: list, metadata: dict):
        """Registrar nuevo procedimiento"""
        self.procedures.register(name, steps, metadata)

    def get_procedure(self, task_type: str) -> dict:
        """Obtener procedimiento para tipo de tarea"""
        return self.procedures.find_best_match(task_type)

    def record_solution(self, problem: str, solution: dict):
        """Registrar solución exitosa"""
        self.solutions.add(problem, solution)

    def find_similar_solution(self, problem: str) -> list:
        """Buscar soluciones similares"""
        return self.solutions.search(problem)
```

### Ejemplo de Uso

```python
# En DEV domain
dev_memory = DomainMemory("/dev")

# Registrar procedimiento
dev_memory.add_procedure(
    name="deploy_api",
    steps=[
        "1. Validar tests",
        "2. Build imagen Docker",
        "3. Push a registry",
        "4. Actualizar deployment",
        "5. Verificar health check"
    ],
    metadata={"environment": "production"}
)

# Usar procedimiento
procedure = dev_memory.get_procedure("desplegar api producción")
```

---

## 7. Memoria Global

### Propósito

Mantener conocimiento a nivel de sistema:
- Decisiones arquitectónicas (ADRs)
- Lecciones aprendidas globales
- Configuración del sistema
- Políticas y normas

### Implementación

```python
class GlobalMemory:
    def __init__(self):
        self.adr_store = ADRStore("memory/global/architecture_decisions/")
        self.lessons = LessonsStore("memory/global/lessons_learned/")
        self.config = SystemConfig("memory/global/system_configuration/")

    def record_decision(self, decision: dict):
        """Registrar decisión arquitectónica (ADR)"""
        adr = ADR(
            title=decision["title"],
            status="accepted",
            context=decision["context"],
            decision=decision["decision"],
            consequences=decision["consequences"]
        )
        self.adr_store.add(adr)

    def record_lesson(self, lesson: dict):
        """Registrar lección aprendida"""
        self.lessons.add(lesson)

    def get_relevant_decisions(self, topic: str) -> list:
        """Buscar decisiones relevantes"""
        return self.adr_store.search(topic)
```

### Ejemplo de ADR

```markdown
# ADR-001: Arquitectura Tri-Agente para Especialistas

## Estado
Aceptado

## Contexto
Necesitamos que las unidades especialistas produzcan resultados
validados y auditables sin intervención humana.

## Decisión
Cada unidad especialista implementa estructura tri-agente:
- Director: Planificación
- Ejecutor: Ejecución
- Archivador: Validación

## Consecuencias
- Positivas: Mayor robustez, auditoría automática
- Negativas: Mayor complejidad, más recursos
```

---

## 8. Integración con Archivador

### Rol del Archivador en Memoria

El Archivador de cada unidad es responsable de:

1. **Observar** todas las transacciones de la unidad
2. **Validar** coherencia de datos
3. **Persistir** en los niveles apropiados de memoria
4. **Indexar** para búsqueda semántica

### Flujo de Persistencia

```
Transacción completada
        │
        ▼
┌───────────────────┐
│   ARCHIVADOR      │
├───────────────────┤
│ 1. Validar datos  │
│ 2. Clasificar     │
│ 3. Determinar     │
│    nivel memo     │
└─────────┬─────────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌────────┐ ┌──────────────┐
│ Agente │ │ Unidad/Dominio│
│ Memo   │ │ Memo          │
└────────┘ └──────────────┘
```

---

## 9. Política de Retención

### Reglas por Tipo de Memoria

| Memoria | Retención | Política |
|---------|-----------|----------|
| **Agente** | 30 días | Conversación se comprime después de 7 días |
| **Unidad** | 90 días | Sesiones archivadas mensualmente |
| **Dominio** | Permanente | Procedimientos nunca se eliminan |
| **Global** | Permanente | ADRs y lecciones son permanentes |

### Compresión de Memoria

```python
class MemoryCompressor:
    def compress_conversation(self, messages: list) -> str:
        """Comprimir conversación antigua en resumen"""
        summary = self.llm.summarize(messages)
        return summary

    def archive_session(self, unit_id: str, session_id: str):
        """Archivar sesión completada"""
        session = self.load_session(unit_id, session_id)
        summary = self.compress_conversation(session.messages)

        # Guardar resumen en lugar de mensajes completos
        self.archive_store.save_summary(unit_id, session_id, summary)
```

---

## 10. APIs de Memoria

### Interfaz Unificada

```python
class MemorySystem:
    def __init__(self, agent_id: str, unit_id: str, domain: str):
        self.agent_memory = AgentMemory(agent_id)
        self.unit_memory = UnitMemory(unit_id)
        self.domain_memory = DomainMemory(domain)
        self.global_memory = GlobalMemory()

    def remember(self, content: dict, level: str = "agent"):
        """Guardar en nivel de memoria especificado"""
        if level == "agent":
            self.agent_memory.remember(content)
        elif level == "unit":
            self.unit_memory.share(content)
        elif level == "domain":
            self.domain_memory.record_solution(content)
        elif level == "global":
            self.global_memory.record_decision(content)

    def recall(self, query: str, levels: list = None) -> dict:
        """Buscar en niveles de memoria"""
        levels = levels or ["agent", "unit", "domain", "global"]
        results = {}

        if "agent" in levels:
            results["agent"] = self.agent_memory.recall(query)
        if "unit" in levels:
            results["unit"] = self.unit_memory.get_shared_context(query)
        if "domain" in levels:
            results["domain"] = self.domain_memory.find_similar_solution(query)
        if "global" in levels:
            results["global"] = self.global_memory.get_relevant_decisions(query)

        return results
```

---

## 11. Configuración

```json
{
  "memory": {
    "backends": {
      "vector_db": "sqlite-vec",
      "document_store": "filesystem",
      "cache": "redis"
    },

    "retention": {
      "agent_memory_days": 30,
      "unit_memory_days": 90,
      "domain_memory": "permanent",
      "global_memory": "permanent"
    },

    "compression": {
      "enabled": true,
      "compress_after_days": 7,
      "llm_model": "glm-4.5-air"
    },

    "indexing": {
      "auto_index": true,
      "embedding_model": "text-embedding-3-small",
      "chunk_size": 512
    }
  }
}
```

---

## Referencias

- [Arquitectura Maestra](../01-SISTEMA/00-arquitectura-maestra.md)
- [Motor de Conocimiento](../10-CONOCIMIENTO/00-knowledge-engine.md)

---

**Documento:** Arquitectura de Memoria
**Ubicación:** `docs/09-MEMORIA/00-arquitectura-memoria.md`
**Versión:** 2.1.0
**Fecha:** 2026-03-09
