# Arquitectura Tri-Agente (Concilio)

**Propietario:** Ruben
**Fecha:** 2026-03-10
**Tipo:** PRODUCCIÓN - Arquitectura Core
**Versión:** 3.0

---

## Visión General

El **Concilio Tri-Agente** es el bloque de construcción fundamental del sistema. Consiste en **3 instancias de proceso** que trabajan en coordinación:

- **Director** - Recibe, planifica, delega, valida, entrega
- **Ejecutor** - Ejecuta, genera, produce
- **Archivador** - Valida, documenta, memoriza

Cada instancia es un proceso Node.js independiente con:
- **Workspace propio** (archivos, configuración, skills)
- **Memoria independiente** (base de datos vectorial propia)
- **Modelo LLM propio** (optimizado para su rol)
- **Puerto propio** (WebSocket server dedicado)

```
┌─────────────────────────────────────────────────────────────────┐
│                      GATEWAY FASTIFY                             │
│                      Puerto: 18789                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │  DIRECTOR   │  │  EJECUTOR   │  │ ARCHIVADOR  │             │
│  │ Puerto:8081 │◄─┤ Puerto:8082 │◄─┤ Puerto:8083 │             │
│  │             │  │             │  │             │             │
│  │ Opus 4.6    │  │ Sonnet 4.6  │  │ Haiku 4.5   │             │
│  │ workspace-  │  │ workspace-  │  │ workspace-  │             │
│  │ director    │  │ ejecutor    │  │ archivador  │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│        ▲                ▲                 ▲                      │
│        │                │                 │                      │
│        └────────────────┴─────────────────┘                      │
│              Redis Pub/Sub (comunicación interna)                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    Usuario (Telegram/Discord)
```

---

## Arquitectura de Componentes

### Stack Tecnológico

| Componente | Tecnología | Puerto | Propósito |
|------------|------------|--------|-----------|
| **Gateway** | Fastify + WebSocket | 18789 | Entrada unificada, routing |
| **Director** | Node.js + LLM SDK | 8081 | Coordinación, delegación |
| **Ejecutor** | Node.js + LLM SDK | 8082 | Ejecución técnica |
| **Archivador** | Node.js + LLM SDK | 8083 | Validación, memoria |
| **Message Broker** | Redis | 6379 | Comunicación inter-agente |
| **Memoria Vectorial** | LanceDB | - | RAG por agente |
| **Cola de Tareas** | BullMQ | - | Gestión de tareas async |

### Estructura de Directorios

```
/Volumes/NVMe-4TB/openclaw/
│
├── gateway/                      ← Gateway Fastify
│   ├── src/
│   │   ├── server.ts
│   │   ├── routes/
│   │   └── websocket/
│   ├── package.json
│   └── tsconfig.json
│
├── orquestador/                  ← Coordinador del Concilio
│   ├── src/
│   │   ├── concilio.ts          ← Lógica del tri-agente
│   │   ├── router.ts            ← Ruteo de mensajes
│   │   └── state.ts             ← Estado compartido
│   └── package.json
│
├── agentes/
│   ├── director/
│   │   ├── src/
│   │   │   ├── agent.ts
│   │   │   ├── prompts/
│   │   │   └── skills/
│   │   └── workspace/
│   │       ├── SOUL.md
│   │       └── memoria/
│   │
│   ├── ejecutor/
│   │   ├── src/
│   │   │   ├── agent.ts
│   │   │   ├── tools/           ← bash, read, write, etc.
│   │   │   └── skills/
│   │   └── workspace/
│   │       └── SOUL.md
│   │
│   └── archivador/
│       ├── src/
│       │   ├── agent.ts
│       │   ├── validation.ts
│       │   └── memoria/
│       └── workspace/
│           ├── SOUL.md
│           └── memoria/
│               ├── decisiones.md
│               ├── patrones.md
│               ├── errores.md
│               └── mejores-practicas.md
│
├── memoria/
│   ├── redis/                   ← Redis data
│   └── vectors/                 ← LanceDB por agente
│
├── logs/
│   ├── gateway.log
│   ├── director.log
│   ├── ejecutor.log
│   └── archivador.log
│
└── mission-control/             ← Dashboard
    └── dashboard/
```

---

## Configuración Principal

### Archivo: `config/concilio.yaml`

```yaml
# Concilio Tri-Agente - Configuración Principal
# Versión: 3.0

concilio:
  nombre: "OPENCLAW-Concilio-Principal"
  version: "3.0"

# Gateway Fastify
gateway:
  puerto: 18789
  host: "0.0.0.0"
  websocket:
    enabled: true
    path: "/ws"
  cors:
    origins: ["*"]

# Los 3 Agentes
agentes:
  director:
    id: "director"
    puerto: 8081
    modelo: "anthropic/claude-opus-4-6"
    thinking_level: "high"
    entry_point: true           # Recibe mensajes del usuario
    herramientas:
      - "agent_comm"            # Comunicación con otros agentes
      - "planning"
    workspace: "./agentes/director/workspace"
    memoria:
      tipo: "lancedb"
      path: "./memoria/vectors/director"

  ejecutor:
    id: "ejecutor"
    puerto: 8082
    modelo: "anthropic/claude-sonnet-4-6"
    thinking_level: "medium"
    entry_point: false
    herramientas:
      - "bash"
      - "read"
      - "write"
      - "edit"
      - "browser"
      - "process"
    workspace: "./agentes/ejecutor/workspace"
    memoria:
      tipo: "lancedb"
      path: "./memoria/vectors/ejecutor"

  archivador:
    id: "archivador"
    puerto: 8083
    modelo: "anthropic/claude-haiku-4-5"
    thinking_level: "medium"
    entry_point: false
    herramientas:
      - "read"
      - "write"
      - "validate"
    workspace: "./agentes/archivador/workspace"
    memoria:
      tipo: "lancedb"
      path: "./memoria/vectors/archivador"
      compartida:
        path: "./memoria/vectors/concilio-shared"

# Redis para comunicación
redis:
  host: "localhost"
  puerto: 6379
  db: 0
  canales:
    director: "concilio:director"
    ejecutor: "concilio:ejecutor"
    archivador: "concilio:archivador"
    broadcast: "concilio:broadcast"

# Cola de tareas (BullMQ)
cola:
  redis: "redis://localhost:6379"
  colas:
    - "director:tasks"
    - "ejecutor:tasks"
    - "archivador:tasks"

# Canales de entrada
canales:
  telegram:
    enabled: true
    bot_token: "${TELEGRAM_BOT_TOKEN}"
    routing: "director"         # Todos los mensajes van al Director

  discord:
    enabled: true
    bot_token: "${DISCORD_BOT_TOKEN}"
    routing: "director"

# Proveedores LLM
proveedores:
  anthropic:
    api_key: "${ANTHROPIC_API_KEY}"

  zai:
    tipo: "openai-compatible"
    base_url: "https://api.z.ai/v1"
    api_key: "${ZAI_API_KEY}"

  minimax:
    tipo: "openai-compatible"
    base_url: "https://api.minimax.chat/v1"
    api_key: "${MINIMAX_API_KEY}"

# Fallbacks de modelos
fallbacks:
  "anthropic/claude-opus-4-6":
    - "zai/glm-5"
    - "minimax/abab6.5s-chat"
  "anthropic/claude-sonnet-4-6":
    - "zai/glm-4.7"
  "anthropic/claude-haiku-4-5":
    - "zai/glm-4.5-air"
```

---

## Comunicación Inter-Agente

### Redis Pub/Sub

Los agentes se comunican vía Redis Pub/Sub con mensajes estructurados:

```typescript
// Tipos de mensaje
interface AgentMessage {
  id: string;                    // UUID
  from: AgentRole;               // 'director' | 'ejecutor' | 'archivador'
  to: AgentRole | 'broadcast';   // Destino
  type: MessageType;             // 'task' | 'result' | 'validation' | 'query'
  correlationId?: string;        // Para request-response
  timestamp: number;
  payload: any;
}

// Ejemplo: Director delega al Ejecutor
const delegacion: AgentMessage = {
  id: uuidv4(),
  from: 'director',
  to: 'ejecutor',
  type: 'task',
  correlationId: 'req-123',
  timestamp: Date.now(),
  payload: {
    tarea: "Crear función Python para calcular factorial",
    requisitos: [
      "Manejar números grandes",
      "Validación de entrada",
      "Documentar con docstring"
    ],
    contexto: "Usuario solicita para proyecto de matemáticas"
  }
};
```

### Implementación del Bus de Mensajes

```typescript
// src/orquestador/message-bus.ts
import Redis from 'ioredis';

export class MessageBus {
  private publisher: Redis;
  private subscriber: Redis;

  constructor() {
    this.publisher = new Redis(process.env.REDIS_URL);
    this.subscriber = new Redis(process.env.REDIS_URL);
  }

  async send(message: AgentMessage): Promise<void> {
    const channel = `concilio:${message.to}`;
    await this.publisher.publish(channel, JSON.stringify(message));
  }

  async broadcast(from: AgentRole, payload: any): Promise<void> {
    const message: AgentMessage = {
      id: uuidv4(),
      from,
      to: 'broadcast',
      type: 'broadcast',
      timestamp: Date.now(),
      payload
    };
    await this.publisher.publish('concilio:broadcast', JSON.stringify(message));
  }

  subscribe(agentId: AgentRole, handler: (msg: AgentMessage) => Promise<void>) {
    const channel = `concilio:${agentId}`;

    this.subscriber.subscribe(channel, 'concilio:broadcast');

    this.subscriber.on('message', async (ch, messageStr) => {
      const message: AgentMessage = JSON.parse(messageStr);
      if (ch === channel || ch === 'concilio:broadcast') {
        await handler(message);
      }
    });
  }
}
```

---

## Flujo de Trabajo Tri-Agente

### Flujo Completo

```
Usuario: "Diseña una API REST para gestión de inventario"
         │
         ▼
    ┌─────────────────────────────────────────────────────┐
    │  GATEWAY (puerto 18789)                              │
    │  Recibe mensaje via Telegram/Discord                 │
    │  Rutea al Director                                   │
    └─────────────────────────────────────────────────────┘
         │
         │ WebSocket → localhost:8081
         ▼
    ┌─────────────────────────────────────────────────────┐
    │  DIRECTOR (puerto 8081)                              │
    │  1. Recibe solicitud                                 │
    │  2. Analiza y planifica                              │
    │  3. Crea plan de trabajo                             │
    │  4. Delega al Ejecutor via Redis                     │
    └─────────────────────────────────────────────────────┘
         │
         │ Redis publish: concilio:ejecutor
         ▼
    ┌─────────────────────────────────────────────────────┐
    │  EJECUTOR (puerto 8082)                              │
    │  1. Recibe tarea delegada                            │
    │  2. Ejecuta trabajo técnico                          │
    │  3. Usa herramientas (bash, write, etc.)            │
    │  4. Produce artefacto                                │
    │  5. Devuelve resultado via Redis                     │
    └─────────────────────────────────────────────────────┘
         │
         │ Redis publish: concilio:director
         ▼
    ┌─────────────────────────────────────────────────────┐
    │  DIRECTOR (puerto 8081)                              │
    │  5. Recibe resultado del Ejecutor                    │
    │  6. Solicita validación al Archivador               │
    └─────────────────────────────────────────────────────┘
         │
         │ Redis publish: concilio:archivador
         ▼
    ┌─────────────────────────────────────────────────────┐
    │  ARCHIVADOR (puerto 8083)                            │
    │  1. Recibe artefacto a validar                       │
    │  2. Verifica calidad y completitud                   │
    │  3. Comprueba contra requisitos                      │
    │  4. Actualiza memoria del sistema                    │
    │  5. Devuelve validación via Redis                    │
    └─────────────────────────────────────────────────────┘
         │
         │ Redis publish: concilio:director
         ▼
    ┌─────────────────────────────────────────────────────┐
    │  DIRECTOR (puerto 8081)                              │
    │  7. Recibe validación                                │
    │  8. Compone respuesta final                          │
    │  9. Entrega al usuario via Gateway                   │
    └─────────────────────────────────────────────────────┘
         │
         ▼
    Usuario recibe respuesta validada
```

---

## Implementación de los Agentes

### Agente Base

```typescript
// src/agentes/base/agent.ts
import { MessageBus, AgentMessage } from '../orquestador/message-bus';
import { LLMClient } from '../llm/client';

export abstract class BaseAgent {
  protected id: string;
  protected puerto: number;
  protected modelo: string;
  protected bus: MessageBus;
  protected llm: LLMClient;
  protected workspace: string;

  constructor(config: AgentConfig) {
    this.id = config.id;
    this.puerto = config.puerto;
    this.modelo = config.modelo;
    this.bus = new MessageBus();
    this.llm = new LLMClient(config.modelo, config.proveedores);
    this.workspace = config.workspace;
  }

  async iniciar(): Promise<void> {
    // Suscribirse a mensajes
    this.bus.subscribe(this.id as AgentRole, this.manejarMensaje.bind(this));

    // Iniciar servidor HTTP para health checks
    await this.iniciarServidor();

    console.log(`Agente ${this.id} iniciado en puerto ${this.puerto}`);
  }

  protected async manejarMensaje(mensaje: AgentMessage): Promise<void> {
    console.log(`[${this.id}] Mensaje recibido de ${mensaje.from}:`, mensaje.type);

    switch (mensaje.type) {
      case 'task':
        await this.procesarTarea(mensaje);
        break;
      case 'result':
        await this.procesarResultado(mensaje);
        break;
      case 'validation':
        await this.procesarValidacion(mensaje);
        break;
      case 'query':
        await this.responderConsulta(mensaje);
        break;
    }
  }

  protected async enviar(destino: AgentRole, tipo: MessageType, payload: any, correlationId?: string): Promise<void> {
    const mensaje: AgentMessage = {
      id: uuidv4(),
      from: this.id as AgentRole,
      to: destino,
      type: tipo,
      correlationId,
      timestamp: Date.now(),
      payload
    };
    await this.bus.send(mensaje);
  }

  // Métodos abstractos a implementar por cada agente
  protected abstract procesarTarea(mensaje: AgentMessage): Promise<void>;
  protected abstract procesarResultado(mensaje: AgentMessage): Promise<void>;
  protected abstract procesarValidacion(mensaje: AgentMessage): Promise<void>;
  protected abstract responderConsulta(mensaje: AgentMessage): Promise<void>;
  protected abstract iniciarServidor(): Promise<void>;
}
```

### Director

```typescript
// src/agentes/director/agent.ts
import { BaseAgent, AgentMessage } from '../base/agent';

export class DirectorAgent extends BaseAgent {
  private tareasPendientes: Map<string, PendingTask> = new Map();

  constructor(config: AgentConfig) {
    super(config);
  }

  async procesarTarea(mensaje: AgentMessage): Promise<void> {
    // El Director recibe solicitudes del usuario
    const solicitud = mensaje.payload;

    // 1. Analizar solicitud
    const analisis = await this.llm.chat([
      { role: 'system', content: this.obtenerPromptSistema() },
      { role: 'user', content: `Analiza esta solicitud y crea un plan:\n\n${JSON.stringify(solicitud)}` }
    ]);

    // 2. Crear plan
    const plan = this.parsearPlan(analisis);

    // 3. Registrar tarea pendiente
    const taskId = mensaje.correlationId || uuidv4();
    this.tareasPendientes.set(taskId, {
      solicitud,
      plan,
      estado: 'delegando',
      timestamp: Date.now()
    });

    // 4. Delegar al Ejecutor
    await this.enviar('ejecutor', 'task', {
      taskId,
      plan: plan.tareasEjecucion,
      contexto: solicitud
    }, taskId);
  }

  async procesarResultado(mensaje: AgentMessage): Promise<void> {
    const { taskId, resultado, estado } = mensaje.payload;

    // Recuperar tarea pendiente
    const tarea = this.tareasPendientes.get(taskId);
    if (!tarea) {
      console.error(`Tarea ${taskId} no encontrada`);
      return;
    }

    tarea.resultadoEjecutor = resultado;
    tarea.estado = 'validando';

    // Solicitar validación al Archivador
    await this.enviar('archivador', 'task', {
      taskId,
      artefacto: resultado,
      requisitos: tarea.plan.requisitos
    }, taskId);
  }

  async procesarValidacion(mensaje: AgentMessage): Promise<void> {
    const { taskId, validacion } = mensaje.payload;

    const tarea = this.tareasPendientes.get(taskId);
    if (!tarea) return;

    tarea.validacion = validacion;

    if (validacion.estado === 'APROBADO') {
      // Entregar respuesta al usuario
      await this.entregarResultado(taskId, tarea);
    } else if (validacion.estado === 'RECHAZADO') {
      // Re-delegar con correcciones
      tarea.estado = 'corrigiendo';
      await this.enviar('ejecutor', 'task', {
        taskId,
        plan: tarea.plan.tareasEjecucion,
        correcciones: validacion.correcciones,
        intento: (tarea.intentos || 0) + 1
      }, taskId);
    } else if (validacion.estado === 'MODIFICACIONES_REQUERIDAS') {
      // Aplicar mejoras menores
      await this.entregarResultado(taskId, tarea, validacion.mejoras);
    }
  }

  private async entregarResultado(taskId: string, tarea: PendingTask, mejoras?: string[]): Promise<void> {
    // Enviar respuesta via Gateway
    // Implementar envío al canal original (Telegram/Discord)
    tarea.estado = 'completado';
  }

  protected obtenerPromptSistema(): string {
    return `
Eres el DIRECTOR del sistema tri-agente.

## Propósito
Coordinar, planificar, delegar y validar el trabajo del sistema.

## Flujo de Trabajo
1. Recibir solicitudes del usuario
2. Analizar y crear plan de trabajo
3. Delegar ejecución al Ejecutor
4. Solicitar validación al Archivador
5. Entregar respuesta final validada

## Formato de Plan
Responde SIEMPRE en JSON:
{
  "analisis": "Descripción del problema",
  "tareasEjecucion": [
    { "descripcion": "...", "prioridad": "alta|media|baja" }
  ],
  "requisitos": ["req1", "req2"],
  "criteriosValidacion": ["criterio1", "criterio2"]
}
    `;
  }
}
```

### Ejecutor

```typescript
// src/agentes/ejecutor/agent.ts
import { BaseAgent, AgentMessage } from '../base/agent';
import { BashTool, ReadTool, WriteTool, EditTool } from './tools';

export class EjecutorAgent extends BaseAgent {
  private tools: Map<string, Tool>;

  constructor(config: AgentConfig) {
    super(config);
    this.tools = new Map([
      ['bash', new BashTool()],
      ['read', new ReadTool()],
      ['write', new WriteTool()],
      ['edit', new EditTool()]
    ]);
  }

  async procesarTarea(mensaje: AgentMessage): Promise<void> {
    const { taskId, plan, contexto, correcciones, intento } = mensaje.payload;

    // Construir prompt con herramientas disponibles
    const toolsDescription = Array.from(this.tools.values())
      .map(t => `- ${t.nombre}: ${t.descripcion}`)
      .join('\n');

    const prompt = correcciones
      ? `${this.obtenerPromptSistema()}\n\nCORRECCIONES SOLICITADAS:\n${correcciones.join('\n')}\n\nTAREA ORIGINAL:\n${JSON.stringify(plan)}`
      : `${this.obtenerPromptSistema()}\n\nTAREA:\n${JSON.stringify(plan)}\n\nCONTEXTO:\n${JSON.stringify(contexto)}`;

    // Ejecutar con LLM
    const resultado = await this.llm.chat([
      { role: 'system', content: prompt },
      { role: 'user', content: 'Ejecuta la tarea y produce el artefacto solicitado.' }
    ], {
      tools: this.tools,
      maxThinkingTokens: 4000
    });

    // Enviar resultado al Director
    await this.enviar('director', 'result', {
      taskId,
      resultado: resultado.contenido,
      estado: 'completado',
      herramientasUsadas: resultado.herramientasUsadas
    }, mensaje.correlationId);
  }

  protected obtenerPromptSistema(): string {
    return `
Eres el EJECUTOR técnico del sistema tri-agente.

## Propósito
Transformar planes en resultados tangibles y funcionales.

## Herramientas Disponibles
- bash: Ejecutar comandos de sistema
- read: Leer archivos
- write: Crear archivos nuevos
- edit: Modificar archivos existentes

## Flujo de Trabajo
1. Recibir tarea delegada del Director
2. Ejecutar trabajo técnico
3. Producir código, documentos, análisis
4. Devolver resultados al Director

## Criterios de Calidad
- Código funcional y testeable
- Documentación clara
- Manejo de errores
- Sigue mejores prácticas

## Formato de Respuesta
Proporciona el artefacto completo (código, documento, etc.) listo para validación.
    `;
  }
}
```

### Archivador

```typescript
// src/agentes/archivador/agent.ts
import { BaseAgent, AgentMessage } from '../base/agent';
import { MemoriaManager } from './memoria/manager';

export class ArchivadorAgent extends BaseAgent {
  private memoria: MemoriaManager;

  constructor(config: AgentConfig) {
    super(config);
    this.memoria = new MemoriaManager(config.workspace + '/memoria');
  }

  async procesarTarea(mensaje: AgentMessage): Promise<void> {
    const { taskId, artefacto, requisitos } = mensaje.payload;

    // Validar artefacto
    const validacion = await this.validarArtefacto(artefacto, requisitos);

    // Si aprobado, actualizar memoria
    if (validacion.estado === 'APROBADO') {
      await this.memoria.registrarDecision({
        fecha: new Date().toISOString(),
        taskId,
        artefacto: artefacto.substring(0, 200) + '...',
        estado: 'aprobado',
        criterios: validacion.criteriosAprobados
      });
    } else {
      await this.memoria.registrarError({
        fecha: new Date().toISOString(),
        taskId,
        error: validacion.motivo,
        correcciones: validacion.correcciones
      });
    }

    // Enviar validación al Director
    await this.enviar('director', 'validation', {
      taskId,
      validacion
    }, mensaje.correlationId);
  }

  private async validarArtefacto(artefacto: any, requisitos: string[]): Promise<Validacion> {
    const prompt = `
Eres el ARCHIVADOR y validador del sistema.

## Tarea
Validar el siguiente artefacto contra los requisitos especificados.

## Requisitos
${requisitos.map((r, i) => `${i + 1}. ${r}`).join('\n')}

## Artefacto a Validar
\`\`\`
${artefacto}
\`\`\`

## Criterios de Validación
1. Cumple todos los requisitos funcionales
2. Sin errores críticos
3. Código/documentación mantenible
4. Sigue convenciones del proyecto

## Formato de Respuesta (JSON)
{
  "estado": "APROBADO" | "RECHAZADO" | "MODIFICACIONES_REQUERIDAS",
  "criteriosAprobados": ["criterio1", "criterio2"],
  "criteriosFallidos": ["criterio3"],
  "motivo": "Descripción del problema",
  "correcciones": ["Sugerencia 1", "Sugerencia 2"],
  "mejoras": ["Mejora opcional 1"]
}
    `;

    const resultado = await this.llm.chat([
      { role: 'system', content: this.obtenerPromptSistema() },
      { role: 'user', content: prompt }
    ]);

    return JSON.parse(resultado.contenido);
  }

  protected obtenerPromptSistema(): string {
    return `
Eres el ARCHIVADOR del sistema tri-agente.

## Propósito
Garantizar calidad, mantener memoria, documentar conocimiento.

## Responsabilidades
1. Validar calidad y corrección de artefactos
2. Documentar decisiones en memoria
3. Mantener registro de patrones y errores
4. Preservar conocimiento del sistema

## Memoria del Sistema
- decisiones.md: Decisiones tomadas
- patrones.md: Patrones identificados
- errores.md: Errores y soluciones
- mejores-practicas.md: Lecciones aprendidas
    `;
  }
}
```

---

## Scripts de Control

### Script de Inicio

```bash
#!/bin/bash
# scripts/concilio-start.sh

set -e

OPENCLAW_ROOT="${OPENCLAW_ROOT:-/Volumes/NVMe-4TB/openclaw}"

echo "🦞 Iniciando Concilio Tri-Agente..."

# Verificar Redis
if ! redis-cli ping > /dev/null 2>&1; then
    echo "❌ Redis no está corriendo. Iniciando..."
    brew services start redis
    sleep 2
fi

# Iniciar los 3 agentes
echo "Iniciando Director (puerto 8081)..."
cd "$OPENCLAW_ROOT/agentes/director"
node dist/agent.js &
echo $! > /tmp/concilio-director.pid

echo "Iniciando Ejecutor (puerto 8082)..."
cd "$OPENCLAW_ROOT/agentes/ejecutor"
node dist/agent.js &
echo $! > /tmp/concilio-ejecutor.pid

echo "Iniciando Archivador (puerto 8083)..."
cd "$OPENCLAW_ROOT/agentes/archivador"
node dist/agent.js &
echo $! > /tmp/concilio-archivador.pid

sleep 2

# Iniciar Gateway
echo "Iniciando Gateway (puerto 18789)..."
cd "$OPENCLAW_ROOT/gateway"
node dist/server.js &
echo $! > /tmp/concilio-gateway.pid

sleep 3

echo ""
echo "✅ Concilio Tri-Agente iniciado"
echo ""
echo "📋 Agentes:"
echo "   • Director   (puerto 8081) - PID: $(cat /tmp/concilio-director.pid)"
echo "   • Ejecutor   (puerto 8082) - PID: $(cat /tmp/concilio-ejecutor.pid)"
echo "   • Archivador (puerto 8083) - PID: $(cat /tmp/concilio-archivador.pid)"
echo ""
echo "🌐 Gateway: http://localhost:18789"
echo ""
```

### Script de Estado

```bash
#!/bin/bash
# scripts/concilio-status.sh

echo "🦞 Estado del Concilio Tri-Agente:"
echo ""

check_agent() {
    local name=$1
    local pidfile="/tmp/concilio-$name.pid"

    if [ -f "$pidfile" ]; then
        pid=$(cat "$pidfile")
        if ps -p $pid > /dev/null 2>&1; then
            echo "✅ $name ACTIVO (PID: $pid)"
        else
            echo "❌ $name CAÍDO (PID existía pero proceso no)"
        fi
    else
        echo "⚠️  $name NO INICIADO"
    fi
}

check_agent "director"
check_agent "ejecutor"
check_agent "archivador"
check_agent "gateway"

echo ""
echo "Redis:"
redis-cli ping 2>/dev/null || echo "❌ Redis no responde"

echo ""
echo "Puertos:"
lsof -i :18789 2>/dev/null | grep LISTEN || echo "   18789 (Gateway): NO ESCUCHANDO"
lsof -i :8081 2>/dev/null | grep LISTEN || echo "   8081 (Director): NO ESCUCHANDO"
lsof -i :8082 2>/dev/null | grep LISTEN || echo "   8082 (Ejecutor): NO ESCUCHANDO"
lsof -i :8083 2>/dev/null | grep LISTEN || echo "   8083 (Archivador): NO ESCUCHANDO"
```

### Script de Parada

```bash
#!/bin/bash
# scripts/concilio-stop.sh

echo "🦞 Deteniendo Concilio Tri-Agente..."

stop_agent() {
    local name=$1
    local pidfile="/tmp/concilio-$name.pid"

    if [ -f "$pidfile" ]; then
        pid=$(cat "$pidfile")
        if ps -p $pid > /dev/null 2>&1; then
            kill $pid
            echo "🛑 $name detenido (PID: $pid)"
        fi
        rm -f "$pidfile"
    fi
}

stop_agent "gateway"
stop_agent "director"
stop_agent "ejecutor"
stop_agent "archivador"

echo "✅ Concilio detenido"
```

---

## Daemon como Servicio (PM2)

### Archivo: `ecosystem.config.js`

```javascript
module.exports = {
  apps: [
    {
      name: 'concilio-director',
      cwd: '/Volumes/NVMe-4TB/openclaw/agentes/director',
      script: 'dist/agent.js',
      env: {
        NODE_ENV: 'production',
        PORT: 8081
      }
    },
    {
      name: 'concilio-ejecutor',
      cwd: '/Volumes/NVMe-4TB/openclaw/agentes/ejecutor',
      script: 'dist/agent.js',
      env: {
        NODE_ENV: 'production',
        PORT: 8082
      }
    },
    {
      name: 'concilio-archivador',
      cwd: '/Volumes/NVMe-4TB/openclaw/agentes/archivador',
      script: 'dist/agent.js',
      env: {
        NODE_ENV: 'production',
        PORT: 8083
      }
    },
    {
      name: 'concilio-gateway',
      cwd: '/Volumes/NVMe-4TB/openclaw/gateway',
      script: 'dist/server.js',
      env: {
        NODE_ENV: 'production',
        PORT: 18789
      }
    }
  ]
};
```

### Gestión con PM2

```bash
# Iniciar todo
pm2 start ecosystem.config.js

# Ver estado
pm2 status

# Ver logs
pm2 logs concilio-director
pm2 logs concilio-ejecutor
pm2 logs concilio-archivador
pm2 logs concilio-gateway

# Reiniciar
pm2 restart all

# Detener
pm2 stop all

# Guardar configuración (auto-inicio)
pm2 save
pm2 startup
```

---

## Checklist de Instalación

```
□ Infraestructura base:
  □ Node.js 22+ instalado
  □ Redis instalado y corriendo
  □ Estructura de directorios creada
  □ Variables de entorno configuradas

□ Dependencias:
  □ cd gateway && npm install
  □ cd orquestador && npm install
  □ cd agentes/director && npm install
  □ cd agentes/ejecutor && npm install
  □ cd agentes/archivador && npm install

□ Configuración:
  □ config/concilio.yaml configurado
  □ API keys configuradas en .env
  □ Telegram/Discord bots creados

□ Código:
  □ npm run build en cada componente
  □ Archivos SOUL.md creados para cada agente
  □ Memoria inicial creada

□ Scripts:
  □ scripts/concilio-start.sh
  □ scripts/concilio-status.sh
  □ scripts/concilio-stop.sh
  □ chmod +x scripts/*.sh

□ PM2:
  □ pm2 start ecosystem.config.js
  □ pm2 save
  □ pm2 startup

□ Verificación:
  □ Gateway responde en localhost:18789
  □ Director responde en localhost:8081
  □ Ejecutor responde en localhost:8082
  □ Archivador responde en localhost:8083
  □ Redis pub/sub funcional

□ Test de flujo:
  □ Enviar mensaje via Telegram
  □ Director recibe y delega
  □ Ejecutor produce resultado
  □ Archivador valida
  □ Usuario recibe respuesta
```

---

## Costos Estimados

| Agente | Modelo | Uso Típico | Costo/mes |
|--------|--------|------------|-----------|
| Director | claude-opus-4-6 | ~30% | $15-30 |
| Ejecutor | claude-sonnet-4-6 | ~50% | $10-20 |
| Archivador | claude-haiku-4-5 | ~20% | $2-5 |
| **Total** | | | **$27-55/mes** |

**Ahorro con fallbacks a Z.ai/Ollama:**
- Configurar fallbacks reduce costos 40-60%
- Modelos locales para tareas simples

---

**Documento:** Arquitectura Tri-Agente (Concilio)
**Ubicación:** `docs/INSTALACION-PERSONAL/09-TRI-AGENTE-OPENCLAW.md`
**Versión:** 3.0 (Arquitectura Custom - Fastify + Redis)
**Fecha:** 2026-03-10
