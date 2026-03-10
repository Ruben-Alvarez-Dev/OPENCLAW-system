# Extensibilidad y Plugins

**ID:** DOC-DES-EXT-001
**Versión:** OPENCLAW-system v1.0
**Fecha:** 2026-03-09
**Estado:** Documentación Técnica

---

## 1. Arquitectura de Extensibilidad

El OPENCLAW-system está diseñado con una arquitectura modular basada en plugins. Todos los componentes principales son extensibles mediante el sistema de Skills, Canales, Proveedores y Tools de OpenClaw.

### 1.1 Tipos de Extensiones

| Tipo | Descripción | Ubicación |
|------|-------------|-----------|
| **Skills** | Capacidades de alto nivel | `~/.openclaw/skills/` |
| **Canales** | Integraciones de mensajería | `src/channels/` |
| **Providers** | Proveedores de IA | `src/providers/` |
| **Tools** | Herramientas del Ejecutor | `src/tools/` |

### 1.2 Sistema de Plugins de OpenClaw

OpenClaw proporciona un SDK completo para desarrollar plugins:

```
┌─────────────────────────────────────────────────────────────┐
│                    OPENCLAW PLUGIN SDK                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Skills    │  │  Channels   │  │  Providers  │         │
│  │    SDK      │  │    SDK      │  │    SDK      │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│         │                 │                 │               │
│         └─────────────────┼─────────────────┘               │
│                           ↓                                 │
│                  ┌─────────────────┐                        │
│                  │   Plugin Host   │                        │
│                  │   (OpenClaw)    │                        │
│                  └─────────────────┘                        │
│                           │                                 │
│         ┌─────────────────┼─────────────────┐               │
│         ↓                 ↓                 ↓               │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐           │
│  │ Lifecycle│     │  Hooks   │     │  Events  │           │
│  │  Hooks   │     │  System  │     │  Bus     │           │
│  └──────────┘     └──────────┘     └──────────┘           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Creación de Nuevos Skills

### 2.1 Estructura de un Skill

```
my-skill/
├── skill.yaml          # Manifiesto del skill
├── package.json        # Dependencias npm
├── src/
│   ├── index.ts        # Punto de entrada
│   ├── tools.ts        # Definición de tools
│   └── handlers.ts     # Manejadores de eventos
├── tests/
│   └── skill.test.ts   # Tests unitarios
└── README.md           # Documentación
```

### 2.2 Manifiesto del Skill (skill.yaml)

```yaml
name: my-custom-skill
version: 1.0.0
description: Skill personalizado para OPENCLAW-system
author: Tu Nombre

# Configuración del skill
config:
  requiresAuth: false
  permissions:
    - filesystem:read
    - network:fetch

# Tools proporcionados
tools:
  - name: search_documentation
    description: Busca en la documentación del proyecto
    parameters:
      type: object
      properties:
        query:
          type: string
          description: Término de búsqueda
        maxResults:
          type: number
          description: Máximo de resultados
          default: 5

# Hooks del ciclo de vida
hooks:
  onLoad: src/index.ts#onLoad
  onUnload: src/index.ts#onUnload

# Dependencias
dependencies:
  - openclaw-core: ^2026.3.0
```

### 2.3 Implementación del Skill

```typescript
// src/index.ts
import { Skill, Tool, ToolResult } from '@openclaw/core';

export class MyCustomSkill implements Skill {
  name = 'my-custom-skill';
  version = '1.0.0';

  async onLoad(context: SkillContext): Promise<void> {
    console.log(`Loading ${this.name} v${this.version}`);
    // Registrar tools
    context.registerTools(this.getTools());
  }

  async onUnload(): Promise<void> {
    console.log(`Unloading ${this.name}`);
    // Cleanup de recursos
  }

  getTools(): Tool[] {
    return [
      {
        name: 'search_documentation',
        description: 'Busca en la documentación',
        parameters: searchDocSchema,
        execute: this.searchDocumentation.bind(this)
      }
    ];
  }

  async searchDocumentation(params: SearchParams): Promise<ToolResult> {
    const { query, maxResults = 5 } = params;
    
    // Implementar búsqueda
    const results = await this.performSearch(query, maxResults);
    
    return {
      success: true,
      output: results,
      metadata: { query, resultCount: results.length }
    };
  }

  private async performSearch(query: string, limit: number) {
    // Lógica de búsqueda
    return [];
  }
}

export default MyCustomSkill;
```

### 2.4 Registro de Tools

```typescript
// src/tools.ts
import { z } from 'zod';

export const searchDocSchema = z.object({
  query: z.string().describe('Término de búsqueda'),
  maxResults: z.number().default(5).describe('Máximo de resultados')
});

export const tools = [
  {
    name: 'search_documentation',
    description: 'Busca en la documentación del proyecto',
    parameters: searchDocSchema,
    category: 'research'
  }
];
```

---

## 3. Creación de Nuevos Canales

### 3.1 SDK de Canales

OpenClaw proporciona un SDK para crear canales de comunicación personalizados.

```typescript
// src/channels/my-channel/index.ts
import { Channel, Message, ChannelConfig } from '@openclaw/channels';

export class MyCustomChannel implements Channel {
  name = 'my-channel';
  type = 'messaging';

  private config: ChannelConfig;
  private client: any;

  async initialize(config: ChannelConfig): Promise<void> {
    this.config = config;
    // Inicializar cliente del canal
    this.client = await this.createClient(config.credentials);
  }

  async connect(): Promise<void> {
    // Establecer conexión con el servicio
    await this.client.connect();
    
    // Registrar webhooks
    await this.registerWebhooks();
  }

  async disconnect(): Promise<void> {
    await this.client.disconnect();
  }

  // Normalización de mensajes entrantes
  normalizeMessage(rawMessage: any): Message {
    return {
      id: rawMessage.id,
      channelId: this.name,
      userId: rawMessage.sender.id,
      content: rawMessage.text,
      timestamp: new Date(rawMessage.timestamp),
      metadata: {
        platform: this.name,
        raw: rawMessage
      }
    };
  }

  // Envío de mensajes salientes
  async sendMessage(message: OutboundMessage): Promise<void> {
    await this.client.send({
      to: message.recipient,
      content: message.content
    });
  }

  private async registerWebhooks(): Promise<void> {
    // Registrar webhook para mensajes entrantes
    this.client.on('message', (raw: any) => {
      const message = this.normalizeMessage(raw);
      this.emit('message', message);
    });
  }
}
```

### 3.2 Autenticación por Plataforma

```typescript
// Autenticación específica
interface ChannelAuth {
  type: 'oauth' | 'api_key' | 'token';
  credentials: Record<string, string>;
}

async function authenticate(auth: ChannelAuth): Promise<void> {
  switch (auth.type) {
    case 'oauth':
      await this.oauthFlow(auth.credentials);
      break;
    case 'api_key':
      await this.validateApiKey(auth.credentials.apiKey);
      break;
    case 'token':
      await this.validateToken(auth.credentials.token);
      break;
  }
}
```

---

## 4. Creación de Nuevos Proveedores de IA

### 4.1 Interfaz de Provider

```typescript
// src/providers/custom-provider.ts
import { LLMProvider, CompletionRequest, CompletionResponse } from '@openclaw/core';

export class CustomProvider implements LLMProvider {
  name = 'custom-provider';
  models = ['custom-model-v1', 'custom-model-v2'];

  private client: CustomClient;

  async initialize(config: ProviderConfig): Promise<void> {
    this.client = new CustomClient(config.apiKey, config.baseUrl);
  }

  async complete(request: CompletionRequest): Promise<CompletionResponse> {
    const response = await this.client.chat({
      model: request.model,
      messages: request.messages,
      temperature: request.temperature ?? 0.7,
      max_tokens: request.maxTokens ?? 4096
    });

    return {
      content: response.choices[0].message.content,
      model: response.model,
      usage: {
        promptTokens: response.usage.prompt_tokens,
        completionTokens: response.usage.completion_tokens,
        totalTokens: response.usage.total_tokens
      }
    };
  }

  async *stream(request: CompletionRequest): AsyncGenerator<string> {
    const stream = await this.client.chatStream({
      model: request.model,
      messages: request.messages
    });

    for await (const chunk of stream) {
      yield chunk.choices[0]?.delta?.content || '';
    }
  }

  // Validar formato de respuesta
  validateResponse(response: any): boolean {
    return response.choices && 
           Array.isArray(response.choices) &&
           response.choices[0]?.message?.content;
  }

  // Limpiar schema para este provider específico
  cleanSchema(tools: Tool[]): any {
    // Algunos providers necesitan formato especial
    return tools.map(tool => ({
      type: 'function',
      function: {
        name: tool.name,
        description: tool.description,
        parameters: tool.parameters
      }
    }));
  }
}
```

### 4.2 Rate Limiting

```typescript
class RateLimiter {
  private requests: number[] = [];
  private limit: number;
  private window: number;

  constructor(limit: number, windowMs: number) {
    this.limit = limit;
    this.window = windowMs;
  }

  async acquire(): Promise<void> {
    const now = Date.now();
    this.requests = this.requests.filter(t => now - t < this.window);

    if (this.requests.length >= this.limit) {
      const waitTime = this.window - (now - this.requests[0]);
      await delay(waitTime);
    }

    this.requests.push(now);
  }
}

// Uso en el provider
async complete(request: CompletionRequest): Promise<CompletionResponse> {
  await this.rateLimiter.acquire();
  return this.client.complete(request);
}
```

---

## 5. Creación de Nuevos Tools

### 5.1 Registro en el Ejecutor

```typescript
// src/tools/my-tool.ts
import { Tool, ToolResult, ToolContext } from '@openclaw/ejecutor';

export const myCustomTool: Tool = {
  name: 'my_custom_tool',
  description: 'Ejecuta una operacion personalizada',
  parameters: z.object({
    input: z.string().describe('Datos de entrada'),
    options: z.object({
      verbose: z.boolean().default(false),
      timeout: z.number().default(30000)
    }).optional()
  }),

  async execute(
    params: any,
    context: ToolContext
  ): Promise<ToolResult> {

    // 1. Validar parametros
    const validated = this.parameters.parse(params);

    // 2. Verificar permisos
    if (!context.permissions.has('my_custom_tool:execute')) {
      throw new PermissionDeniedError('my_custom_tool:execute');
    }

    // 3. Ejecutar en sandbox
    const result = await context.sandbox.execute({
      command: 'my-tool',
      args: [validated.input],
      timeout: validated.options?.timeout
    });

    // 4. Retornar resultado estructurado
    return {
      success: result.exitCode === 0,
      output: result.stdout,
      error: result.stderr || undefined,
      metadata: {
        executionTime: result.duration,
        exitCode: result.exitCode
      }
    };
  }
};

// Registrar en el Ejecutor
ejecutor.registerTool(myCustomTool);
```

### 5.2 Validación de Parámetros

```typescript
import { z } from 'zod';

const toolSchema = z.object({
  path: z.string().min(1).describe('Ruta del archivo'),
  mode: z.enum(['read', 'write', 'append']).default('read'),
  encoding: z.enum(['utf-8', 'binary']).default('utf-8')
});

// Validar antes de ejecutar
function validateParams(params: unknown): ValidatedParams {
  return toolSchema.parse(params);
}
```

### 5.3 Ejecución Sandboxed

```typescript
async function executeSandboxed(
  command: string, 
  options: ExecutionOptions
): Promise<SandboxResult> {
  
  const sandbox = await createSandbox({
    image: 'openclaw/tool-sandbox:latest',
    timeout: options.timeout,
    memory: options.maxMemory || '256MB'
  });

  try {
    const result = await sandbox.exec(command, {
      cwd: options.workDir,
      env: options.env,
      stdin: options.stdin
    });

    return {
      stdout: result.stdout,
      stderr: result.stderr,
      exitCode: result.exitCode,
      duration: result.duration
    };
  } finally {
    await sandbox.cleanup();
  }
}
```

---

## 6. Testing de Plugins

### 6.1 Unit Tests

```typescript
// tests/my-skill.test.ts
import { describe, it, expect, vi } from 'vitest';
import { MyCustomSkill } from '../src';

describe('MyCustomSkill', () => {
  it('should register tools on load', async () => {
    const context = { registerTools: vi.fn() };
    const skill = new MyCustomSkill();
    
    await skill.onLoad(context);
    
    expect(context.registerTools).toHaveBeenCalledWith(
      expect.arrayContaining([
        expect.objectContaining({ name: 'search_documentation' })
      ])
    );
  });

  it('should execute search tool correctly', async () => {
    const skill = new MyCustomSkill();
    const result = await skill.searchDocumentation({ 
      query: 'test', 
      maxResults: 5 
    });
    
    expect(result.success).toBe(true);
    expect(result.output).toBeDefined();
  });
});
```

### 6.2 Integration Tests

```typescript
// tests/my-skill.integration.test.ts
import { describe, it, expect, beforeAll } from 'vitest';
import { createTestEjecutor } from '@openclaw/testing';

describe('MyCustomSkill Integration', () => {
  let ejecutor: TestEjecutor;

  beforeAll(async () => {
    ejecutor = await createTestEjecutor({
      skills: ['my-custom-skill']
    });
  });

  it('should be callable through ejecutor', async () => {
    const result = await ejecutor.executeTool('search_documentation', {
      query: 'instalacion'
    });

    expect(result.success).toBe(true);
  });
});
```

---

## 7. Publicación de Plugins

### 7.1 Marketplace Interno

```bash
# Publicar skill
openclaw skills publish ./my-skill

# Instalar desde marketplace
openclaw skills install my-custom-skill
```

### 7.2 Instalación vía pnpm

```bash
# Desde npm registry
pnpm add @openclaw-skill/my-custom-skill

# Desde GitHub
pnpm add github:org/my-custom-skill
```

### 7.3 Versionado

Seguir **Semantic Versioning**:
- `MAJOR`: Cambios incompatibles
- `MINOR`: Nueva funcionalidad compatible
- `PATCH`: Bug fixes

---

## 8. Ejemplos de Plugins Existentes

### 8.1 gifgrep

Busca y envía GIFs desde Tenor/Giphy.

```typescript
const gifgrep: Skill = {
  name: 'gifgrep',
  tools: [{
    name: 'search_gif',
    description: 'Busca GIFs por término',
    execute: async (params) => {
      const gifs = await tenor.search(params.query);
      return { success: true, output: gifs[0].url };
    }
  }]
};
```

### 8.2 blogwatcher

Monitorea blogs y envía actualizaciones.

```typescript
const blogwatcher: Skill = {
  name: 'blogwatcher',
  tools: [{
    name: 'watch_blog',
    description: 'Monitorea un blog RSS',
    execute: async (params) => {
      const feed = await parseRSS(params.url);
      return { success: true, output: feed.items };
    }
  }]
};
```

### 8.3 mcporter (MCP Connector)

Conecta con servidores Model Context Protocol.

```typescript
const mcporter: Skill = {
  name: 'mcporter',
  tools: [{
    name: 'mcp_call',
    description: 'Llama a herramienta MCP',
    execute: async (params) => {
      const client = await connectMCP(params.server);
      const result = await client.call(params.tool, params.args);
      return { success: true, output: result };
    }
  }]
};
```

---

## 9. Referencias

- [Guía de Desarrollo](./00-guia-desarrollo.md)
- [Testing](./01-testing.md)
- [OpenClaw Plugin SDK](https://openclaw.ai/docs/plugins)

---

**Última actualización:** 2026-03-09  
**Mantenido por:** Equipo de Desarrollo OPENCLAW-system
