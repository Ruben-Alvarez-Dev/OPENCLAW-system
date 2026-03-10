# Glosario de Términos

**ID:** DOC-REF-GLO-001
**Versión:** 1.1
**Última actualización:** 2026-03-10
**Estado:** Referencia Oficial

---

## Uso del Glosario

Este glosario proporciona definiciones técnicas de términos utilizados en la documentación de OPENCLAW-system y OpenClaw.

---

## A

### Agente
Entidad de software autónoma que percibe su entorno, razona y toma acciones para lograr objetivos. En OPENCLAW-system, los agentes procesan mensajes y ejecutan tareas.

### Agentic Workflow
Flujo de trabajo donde múltiples agentes colaboran para completar tareas complejas, con delegación, supervisión y coordinación.

### Archivador
Agente especializado en validación, gestión de memoria y conocimiento. En el patrón Tri-Agente, responsable de validar resultados, documentar y actualizar la memoria del sistema.

### A2UI
Artificial Intelligence to User Interface - Sistema de generación de interfaces desde descripciones. Ver OpenClaw UI.

### API
Application Programming Interface - Conjunto de protocolos y herramientas para construir software. En OPENCLAW-system, REST y WebSocket APIs.

---

## B

### Backend
Capa de servidor de una aplicación. En OPENCLAW-system, incluye Gateway, agentes, y servicios core.

### BlueBubbles
Servidor de mensajería que permite integración con iMessage en macOS. Canal soportado por OpenClaw.

### Build
Proceso de compilación de código fuente a artefactos ejecutables. TypeScript → JavaScript, assets optimization.

### Browser Automation
Control programático de navegadores web para testing, scraping, o interacción. OpenClaw usa Playwright.

---

## C

### OPENCLAW-system
Sistema multi-agente jerárquico basado en OpenClaw para gestión de conocimiento conversacional, con orquestación, especialización por dominio y unidades de verificación tri-agente.

### CLI
Command Line Interface - Interfaz de línea de comandos para interactuar con el sistema. `openclaw` CLI.

### CDP
Chrome DevTools Protocol - Protocolo para control programático de Chrome/Chromium. Usado en browser automation.

### Context Window
Cantidad máxima de tokens que un modelo LLM puede procesar en una solicitud. Varía de 4K a 2M tokens según modelo.

### Cohere
Proveedor de LLM y embeddings. Modelos: Command R+, embed-v3.

### Core
Módulo central de OpenClaw que proporciona funcionalidades base: configuración, logging, utilidades.

---

## D

### Daemon
Proceso en segundo plano que se ejecuta continuamente. PM2 gestiona daemons de OPENCLAW-system.

### Docker
Plataforma de containerización para empaquetar y ejecutar aplicaciones en entornos aislados.

### Discord
Plataforma de mensajería con soporte para bots. Canal soportado por OpenClaw vía Gateway WebSocket.

---

## E

### Embeddings
Representaciones vectoriales de texto que capturan significado semántico. Usados para búsqueda y RAG.

### E2E
End-to-End - Tests que verifican el flujo completo del sistema desde inicio hasta fin.

### Env
Environment variables - Variables de entorno para configuración de aplicaciones.

### Exec-Approval
Mecanismo de aprobación de ejecución. Herramientas sensibles requieren aprobación antes de ejecutarse.

---

## F

### Fallback
Mecanismo de respaldo cuando el recurso primario falla. Model fallback: Sonnet → GPT-4o → Haiku.

### Fork Mode
Modo de ejecución de PM2 donde cada instancia corre en su propio proceso Node.js.

---

## G

### Gateway
Punto de entrada para comunicación con el sistema. WebSocket Gateway en ws://127.0.0.1:18789.

### GPT
Generative Pre-trained Transformer - Familia de modelos de OpenAI. GPT-4o, GPT-4-turbo, o1, o3.

### Gemini
Familia de modelos de Google. Gemini 2.0 Flash, Gemini 1.5 Pro.

### GLM
General Language Model - Modelos de Zhipu AI. GLM-4, GLM-4-Plus.

---

## H

### Haiku
Claude 3.5 Haiku - Modelo rápido y económico de Anthropic para tareas simples.

---

## I

### IA
Inteligencia Artificial - Campo de la informática que crea sistemas capaces de realizar tareas que requieren inteligencia humana.

### Integration Test
Tests que verifican la interacción entre múltiples componentes del sistema.

### iMessage
Servicio de mensajería de Apple. Integración vía BlueBubbles.

---

## J

### JSON
JavaScript Object Notation - Formato de intercambio de datos ligero. Usado en APIs y configuración.

### JWT
JSON Web Token - Estándar para transmitir información segura entre partes como objeto JSON.

---

## K

### Kubernetes
Plataforma de orquestación de containers para despliegue, escalado y gestión de aplicaciones containerizadas.

---

## L

### LanceDB
Base de datos vectorial embedded, sin servidor. Usada para memoria de agentes en OpenClaw.

### LLM
Large Language Model - Modelos de lenguaje entrenados con grandes cantidades de texto. GPT-4, Claude, Gemini.

### Logs
Registros de eventos del sistema. Logs estructurados facilitan debugging y monitoreo.

### Llama
Familia de modelos open-source de Meta. Llama 3.3 70B, Llama 3.2.

---

## M

### Director
Agente que planifica, coordina y delega tareas. En el patrón Tri-Agente, responsable de la planificación estratégica y la distribución de trabajo. Ver Patrón Supervisor.

### MCP
Model Context Protocol - Protocolo para conectar modelos con herramientas y recursos externos.

### Memory
Sistema de almacenamiento y recuperación de información para agentes. LanceDB, SQLite-vec, PostgreSQL.

### Mermaid
Lenguaje para crear diagramas en Markdown. Usado en documentación técnica.

### Mistral
Empresa francesa de IA. Modelos: Mistral Large, Mistral Medium, Codestral.

### MM
Multi-Modal - Modelos que procesan múltiples tipos de datos: texto, imágenes, audio.

### MMR
Maximal Marginal Relevance - Algoritmo para diversificar resultados de búsqueda.

### MCP-Connector
Componente que conecta OpenClaw con servidores MCP externos.

### MSTeams
Microsoft Teams - Plataforma de colaboración. Canal soportado por OpenClaw.

---

## N

### NATS
Sistema de mensajería de alto rendimiento. Alternativa para comunicación entre agentes.

### Node.js
Runtime de JavaScript asíncrono. Plataforma base de OpenClaw y OPENCLAW-system.

### npm
Node Package Manager - Gestor de paquetes de Node.js.

### NPM_HOME
Variable de entorno que especifica ubicación de paquetes npm globales.

---

## O

### Obsidian
Aplicación de notas con soporte para links y graph view. Posible integración para knowledge base.

### OpenAI
Empresa de IA. Modelos: GPT-4o, o1, o3, Whisper, DALL-E. Fundadores: Sam Altman, otros.

### OpenClaw
Framework open-source de orquestación de agentes de IA. Base de OPENCLAW-system.

### Ollama
Herramienta para ejecutar LLMs localmente. Soporta Llama, Mistral, Gemma, etc.

---

## P

### PM2
Process Manager 2 - Gestor de procesos para Node.js con clustering, monitoring, y restart automático.

### PostgreSQL
Base de datos relacional open-source. Con pgvector para búsqueda vectorial.

### Playwright
Framework de browser automation. Usado en OpenClaw para control de navegadores.

### pnpm
Gestor de paquetes rápido y eficiente en disco. Alternativa a npm.

### Prompt
Instrucción o entrada proporcionada a un modelo LLM para generar una respuesta.

### Provider
Proveedor de servicios de IA. OpenAI, Anthropic, Google, xAI, etc.

---

## Q

### QA
Quality Assurance - Aseguramiento de calidad mediante testing y validación.

---

## R

### RAG
Retrieval Augmented Generation - Técnica que combina recuperación de documentos con generación LLM.

### RabbitMQ
Message broker que implementa AMQP. Alternativa a NATS para colas de mensajes.

### R-P-V
Read-Process-Validate - Patrón de procesamiento de datos.

### Rate Limiting
Limitación de velocidad de requests para prevenir abuso y garantizar disponibilidad.

### Regression Test
Tests que verifican que cambios recientes no han roto funcionalidad existente.

---

## S

### Sandbox
Entorno aislado para ejecutar código de forma segura. Docker, gVisor, Kata.

### Slack
Plataforma de comunicación empresarial. Canal soportado por OpenClaw.

### SQLite
Base de datos embedded, serverless. Usada en desarrollo y edge.

### SQLite-vec
Extensión de SQLite para búsqueda vectorial.

### STT
Speech-to-Text - Transcripción de audio a texto. Whisper, Deepgram, Google Speech.

### SSD
Solid State Drive - Almacenamiento de estado sólido. Recomendado para databases.

### Streaming
Transmisión continua de datos. Respuestas LLM streaming, WebSocket streaming.

### Sonnet
Claude 3.5 Sonnet - Modelo balanceado de Anthropic para tareas generales y coding.

### systemd
Sistema de inicio y gestor de servicios en Linux. Alternativa a PM2.

---

## T

### TDD
Test-Driven Development - Metodología donde tests se escriben antes del código.

### Telegram
Plataforma de mensajería. Canal soportado por OpenClaw vía Bot API.

### Tier
Nivel de capacidad o servicio. Tier 1 providers (premium), Tier 2 (competitive), etc.

### Tools
Funciones ejecutables disponibles para agentes. File operations, API calls, browser control.

### Tri-Agente (Triunvirato)
Patrón de tres agentes especializados: Director (planificación), Ejecutor (ejecución), Archivador (validación). Cada unidad especialista en OPENCLAW-system implementa este patrón para garantizar resultados validados y auditables.

### TypeScript
Superset de JavaScript con tipado estático. Lenguaje principal de OpenClaw.

### TUI
Terminal User Interface - Interfaz de usuario en terminal.

---

## U

### UI
User Interface - Interfaz de usuario. Web UI, TUI, o A2UI.

### Unit Test
Tests que verifican unidades individuales de código (funciones, clases).

---

## V

### Vault
Herramienta de HashiCorp para gestión de secretos. Almacenamiento seguro de API keys.

### Vector Store
Base de datos especializada en almacenar y buscar embeddings vectoriales.

### Vitest
Framework de testing rápido para Vite/TypeScript. Usado en OPENCLAW-system.

---

## W

### WebSocket
Protocolo de comunicación full-duplex sobre TCP. Usado en Gateway de OPENCLAW-system.

### WhatsApp
Plataforma de mensajería. Canal en beta para OpenClaw.

### Ejecutor
Agente especializado en ejecutar tareas y generar resultados. En el patrón Tri-Agente, responsable de la ejecución técnica y generación de código o contenido.

### ws://127.0.0.1:18789
Endpoint del Gateway WebSocket de OpenClaw/OPENCLAW-system.

---

## X

### xAI
Empresa de IA de Elon Musk. Modelos: Grok-2, Grok-2-mini.

---

## Z

### Zod
Biblioteca TypeScript para validación de schemas con inferencia de tipos.

### Zero Config
Configuración automática sin necesidad de setup manual.

### zai
Alias abreviado para Zhipu AI.

---

## Referencias Cruzadas

| Documento | Términos Principales |
|-----------|---------------------|
| [00-openclaw-docs.md](00-openclaw-docs.md) | OpenClaw, Gateway, CLI, Módulos |
| [01-ai-providers.md](01-ai-providers.md) | LLM, Embeddings, STT, Providers |
| [02-architectures.md](02-architectures.md) | Triunvirato, Agentes, Patrones |
| [03-best-practices.md](03-best-practices.md) | TDD, SOLID, Rate Limiting, Logs |

---

## Recursos Externos

| Término | Referencia |
|---------|------------|
| LLM | https://en.wikipedia.org/wiki/Large_language_model |
| RAG | https://www.cloudflare.com/learning/ai/what-is-retrieval-augmented-generation/ |
| MCP | https://modelcontextprotocol.io/ |
| WebSocket | https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API |
| TypeScript | https://www.typescriptlang.org/docs/ |

---

> **Nota:** Para términos específicos de configuración, ver documentación técnica correspondiente.
