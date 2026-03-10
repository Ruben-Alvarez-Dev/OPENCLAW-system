# Documentación OpenClaw Consolidada

**ID:** DOC-REF-OPN-001
**Versión:** v2026.3.8
**Última actualización:** 2026-03-10
**Estado:** Referencia Oficial

---

## Resumen de OpenClaw

OpenClaw es un framework de orquestación de agentes de IA de código abierto, diseñado para facilitar la creación, configuración y ejecución de agentes inteligentes multi-modelo. El sistema proporciona una arquitectura modular que permite integrar múltiples proveedores de LLM, herramientas externas y canales de comunicación.

### Información del Proyecto

| Aspecto | Detalle |
|---------|---------|
| Repositorio | `github.com/openclaw/openclaw` |
| Licencia | MIT |
| Lenguaje Principal | TypeScript/Node.js |
| Runtime | Node.js 18+ |
| Gestor de Paquetes | pnpm |

---

## Arquitectura General

OpenClaw v2026.3.8 está compuesto por **9 módulos core** que proporcionan funcionalidades específicas:

```
┌─────────────────────────────────────────────────────────────────┐
│                     OPENCLAW CORE v2026.3.8                     │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐            │
│  │ AGENTS  │  │CHANNELS │  │ MEMORY  │  │BROWSER  │            │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘            │
│       │            │            │            │                  │
│  ┌────┴────┐  ┌────┴────┐  ┌────┴────┐  ┌────┴────┐            │
│  │ GATEWAY │  │  TOOLS  │  │  SANDBOX│  │  CLI    │            │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘            │
│                         │                                       │
│                    ┌────┴────┐                                  │
│                    │  CORE   │                                  │
│                    └─────────┘                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Descripción de Módulos

| Módulo | Función | Estado |
|--------|---------|--------|
| **Core** | Núcleo del sistema, gestión de configuración y utilidades base | Estable |
| **Agents** | Orquestación y gestión de agentes de IA | Estable |
| **Channels** | Integración con plataformas de mensajería (Slack, Discord, Telegram, etc.) | Estable |
| **Memory** | Sistema de memoria persistente y vector store | Estable |
| **Browser** | Automatización de navegador via Playwright/CDP | Estable |
| **Gateway** | Gateway WebSocket para comunicación inter-agente | Estable |
| **Tools** | Herramientas ejecutables para agentes | Estable |
| **Sandbox** | Aislamiento de ejecución (Docker, gVisor) | Beta |
| **CLI** | Interfaz de línea de comandos | Estable |

---

## Características Principales

### 1. Multi-Modelo
- Soporte para 30+ proveedores de LLM
- Fallback automático entre modelos
- Enrutamiento inteligente por tipo de tarea
- Gestión de rate limits y cuotas

### 2. Sistema de Memoria
- **LanceDB**: Vector store integrado
- **SQLite-vec**: Búsqueda vectorial local
- **PostgreSQL + pgvector**: Producción escalable
- Soporte para embeddings múltiples (OpenAI, Cohere, Voyage, Ollama)

### 3. Canales de Comunicación
| Canal | Protocolo | Estado |
|-------|-----------|--------|
| Slack | RTM/WebSocket | ✅ Estable |
| Discord | Gateway WebSocket | ✅ Estable |
| Telegram | Bot API | ✅ Estable |
| iMessage (BlueBubbles) | HTTP API | ✅ Estable |
| WhatsApp | Web API | ⚠️ Beta |
| Microsoft Teams | Bot Framework | ⚠️ Beta |

### 4. Automatización de Navegador
- Playwright integration
- Chrome DevTools Protocol (CDP)
- Headless y headed modes
- Soporte para screenshots y PDFs

### 5. Sistema de Herramientas
- MCP (Model Context Protocol) compatible
- Tools personalizadas via TypeScript
- Sandbox de ejecución
- Aprobación de ejecución (Exec-Approval)

---

## Soporte Multi-Plataforma

| Plataforma | Soporte | Notas |
|------------|---------|-------|
| macOS | ✅ Completo | Plataforma primaria de desarrollo |
| Linux | ✅ Completo | Recomendado para producción |
| Windows | ⚠️ Parcial | WSL2 recomendado |
| Docker | ✅ Completo | Imágenes oficiales disponibles |

### Requisitos del Sistema

```yaml
mínimo:
  node: "18.x"
  ram: "4GB"
  storage: "10GB"

recomendado:
  node: "20.x LTS"
  ram: "8GB"
  storage: "50GB"
  cpu: "4 cores"

producción:
  node: "20.x LTS"
  ram: "16GB+"
  storage: "100GB+ SSD"
  cpu: "8+ cores"
```

---

## Módulos Relevantes para OPENCLAW-system

### Agents Module
El módulo de agentes es el componente central para OPENCLAW-system:

```typescript
// Configuración de agente
interface AgentConfig {
  name: string;
  model: string;
  provider: string;
  systemPrompt: string;
  tools: ToolDefinition[];
  memory: MemoryConfig;
  channels: ChannelConfig[];
}
```

**Capacidades:**
- Creación de agentes dinámicos
- Gestión de prompts y contexto
- Delegación entre agentes
- Patrones: Tri-Agente, Supervisor, Observador

### Channels Module
Integración con plataformas de mensajería:

| Componente | Descripción |
|------------|-------------|
| ChannelAdapter | Interfaz base para canales |
| MessageRouter | Enrutamiento de mensajes |
| EventProcessor | Procesamiento de eventos |
| RateLimiter | Control de velocidad |

### Memory Module
Sistema de memoria persistente:

```typescript
interface MemoryConfig {
  provider: 'lancedb' | 'sqlite-vec' | 'postgres';
  embeddings: EmbeddingConfig;
  chunkSize: number;
  overlap: number;
}
```

### Browser Module
Automatización web:

| Característica | Descripción |
|----------------|-------------|
| Playwright | Automatización de navegador |
| CDP | Chrome DevTools Protocol |
| Screenshots | Captura de pantalla |
| PDF Generation | Generación de documentos |

### Gateway Module
Gateway WebSocket para comunicación:

```
ws://127.0.0.1:18789
```

**Protocolo:**
```json
{
  "type": "message | command | event",
  "payload": {},
  "metadata": {
    "agent": "string",
    "timestamp": "ISO-8601",
    "correlationId": "uuid"
  }
}
```

---

## CLI de OpenClaw

### Comandos Principales

```bash
# Inicialización
openclaw init [project-name]
openclaw config

# Gestión de agentes
openclaw agent create <name>
openclaw agent list
openclaw agent run <name>
openclaw agent stop <name>

# Gestión de canales
openclaw channel add <type>
openclaw channel list
openclaw channel connect <name>

# Memoria
openclaw memory init
openclaw memory query <text>
openclaw memory stats

# Sistema
openclaw start [--gateway]
openclaw status
openclaw logs [agent-name]
openclaw version
```

### Opciones Globales

| Opción | Descripción |
|--------|-------------|
| `--config <path>` | Ruta al archivo de configuración |
| `--env <file>` | Archivo de variables de entorno |
| `--log-level <level>` | Nivel de logging (debug, info, warn, error) |
| `--json` | Salida en formato JSON |
| `--no-color` | Deshabilitar colores |

---

## Integración con OPENCLAW-system

### Configuración del Gateway

```yaml
# openclaw-system.yaml
gateway:
  host: 127.0.0.1
  port: 18789
  protocol: ws

agents:
  archivador:
    model: claude-3-5-sonnet-20241022
    provider: anthropic
    role: validador-memoria

  director:
    model: gpt-4-turbo
    provider: openai
    role: planificador

  ejecutor:
    model: claude-3-5-haiku-20241017
    provider: anthropic
    role: ejecutor

memory:
  provider: lancedb
  path: ./data/memory
  
channels:
  - type: slack
    token: ${SLACK_BOT_TOKEN}
  - type: discord
    token: ${DISCORD_BOT_TOKEN}
```

### Endpoints del Gateway

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/` | WebSocket | Conexión principal |
| `/health` | GET | Health check |
| `/metrics` | GET | Métricas Prometheus |
| `/agents` | GET | Lista de agentes activos |

---

## Limitaciones Conocidas

### Build A2UI
- El build de la interfaz A2UI puede fallar en algunos entornos
- Workaround: Usar CLI exclusivamente
- Issue tracking: GitHub Issues (revisar repo para issues activos)

### Skills Frágiles
- Las skills personalizadas pueden romperse entre versiones
- Recomendación: Versionar skills con el proyecto
- Testing obligatorio antes de upgrades

### Otras Limitaciones

| Limitación | Impacto | Mitigación |
|------------|---------|------------|
| Rate limiting | Alta | Implementar backoff exponencial |
| Context window | Media | Chunking inteligente |
| Memory bloat | Media | Limpiar memoria periódicamente |
| WebSocket reconexión | Baja | Implementar heartbeat |

---

## Recursos Oficiales

### Repositorios
| Recurso | URL |
|---------|-----|
| GitHub Principal | https://github.com/openclaw/openclaw |
| Documentación | https://docs.openclaw.io |
| Examples | https://github.com/openclaw/examples |

### Comunidad
| Plataforma | Enlace |
|------------|--------|
| Discord | https://discord.gg/openclaw |
| Discussions | https://github.com/openclaw/openclaw/discussions |
| Twitter | @openclaw_ai |

### Documentación Técnica
| Documento | Descripción |
|-----------|-------------|
| API Reference | Referencia completa de la API |
| Architecture Guide | Guía de arquitectura |
| Contributing | Guía de contribución |
| Changelog | Historial de cambios |

---

## Referencias Internas

| Documento | Ubicación |
|-----------|-----------|
| Arquitectura OPENCLAW-system | [../01-SISTEMA/00-arquitectura-maestra.md](../01-SISTEMA/00-arquitectura-maestra.md) |
| Proveedores de IA | [01-ai-providers.md](01-ai-providers.md) |
| Arquitecturas de Referencia | [02-architectures.md](02-architectures.md) |
| Best Practices | [03-best-practices.md](03-best-practices.md) |
| Glosario | [04-glosario.md](04-glosario.md) |

---

## Historial de Versiones

| Versión | Fecha | Cambios Principales |
|---------|-------|---------------------|
| v2026.3.8 | 2026-03 | Multi-provider mejorado, Gateway v2 |
| v2026.2.1 | 2026-02 | Memory optimization, nuevos canales |
| v2026.1.0 | 2026-01 | Release inicial del año |

---

> **Nota:** Este documento es parte de la documentación de referencia de OPENCLAW-system v2.1.0. Para información específica de implementación, consultar los documentos de arquitectura y guías de desarrollo.
