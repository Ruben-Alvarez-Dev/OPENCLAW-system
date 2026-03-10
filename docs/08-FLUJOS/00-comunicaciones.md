# Comunicación: Gateway y Protocolos

**ID:** DOC-FLU-COM-001
**Versión:** 2.1.0
**Fecha:** 2026-03-09
**Gateway:** ws://127.0.0.1:18789

---

## Resumen Ejecutivo

El sistema de comunicación de OPENCLAW-system se basa en un **Gateway unificado** que maneja tanto HTTP como WebSocket. El Gateway implementa una API compatible con OpenAI, permite autenticación multi-modo, y sirve como punto central para la comunicación entre engranajes, canales externos, y el usuario final.

---

## 1. Arquitectura del Gateway

### 1.1 Visión General

```mermaid
graph TB
    subgraph "CLIENTES"
        USER[Usuario]
        TG[Telegram]
        WA[WhatsApp]
        DC[Discord]
    end
    
    subgraph "GATEWAY - ws://127.0.0.1:18789"
        HTTP[HTTP Server]
        WS[WebSocket Server]
        AUTH[Auth Module]
        PROTO[Protocol Schemas]
    end
    
    subgraph "AGENTES"
        DIR[Director]
        EJEC[Ejecutor]
        ARCH[Archivador]
    end
    
    subgraph "PROVEEDORES"
        ZAI[Z.ai]
        OAI[OpenAI]
        ANT[Anthropic]
    end
    
    USER -->|HTTP| HTTP
    TG -->|API| HTTP
    WA -->|API| HTTP
    DC -->|API| HTTP
    
    HTTP --> AUTH
    WS --> AUTH
    AUTH --> PROTO
    
    PROTO --> DIR
    PROTO --> EJEC
    PROTO --> ARCH

    DIR --> ZAI
    EJEC --> OAI
    ARCH --> ANT
```

### 1.2 Componentes del Gateway

| Componente | Archivo | Función |
|------------|---------|---------|
| **HTTP Server** | `src/gateway/server.ts` | API REST y WebUI |
| **WebSocket** | `src/gateway/client.ts` | Comunicación real-time |
| **Auth Module** | `src/gateway/auth.ts` | Autenticación |
| **Protocol** | `src/gateway/protocol/` | Schemas de mensajes |
| **OpenAI HTTP** | `src/gateway/openai-http.ts` | API compatible |

---

## 2. Configuración del Gateway

### 2.1 Config Básica

```json
{
  "gateway": {
    "port": 18789,
    "bind": "127.0.0.1",
    "auth": {
      "mode": "token",
      "token": "d91adb5e7091a088e3b1958e9dbd33f4686e7f21fef02844"
    },
    "runtime": "node",
    "tailscale": false,
    "cors": {
      "enabled": true,
      "origins": ["http://localhost:*"]
    }
  }
}
```

### 2.2 URLs de Acceso

| Recurso | URL |
|---------|-----|
| **Web UI** | http://127.0.0.1:18789/ |
| **Web UI (token)** | http://127.0.0.1:18789/#token=d91adb... |
| **WebSocket** | ws://127.0.0.1:18789 |
| **API OpenAI** | http://127.0.0.1:18789/v1/chat/completions |

---

## 3. Protocolo WebSocket

### 3.1 Conexión

```javascript
// Conexión con autenticación
const ws = new WebSocket('ws://127.0.0.1:18789', {
  headers: {
    'Authorization': 'Bearer d91adb5e7091a088e3b1958e9dbd33f4686e7f21fef02844'
  }
});

ws.onopen = () => {
  console.log('Conectado al Gateway');
};

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  handleGatewayMessage(message);
};
```

### 3.2 Schemas de Mensajes

```typescript
// src/gateway/protocol/schema/
interface GatewayMessage {
  type: 'request' | 'response' | 'event';
  id: string;
  timestamp: number;
  payload: unknown;
}

interface ChatRequest {
  type: 'chat';
  sessionId?: string;
  messages: Message[];
  options?: ChatOptions;
}

interface ChatResponse {
  type: 'chat.response';
  sessionId: string;
  content: string;
  toolCalls?: ToolCall[];
  metadata: ResponseMetadata;
}

interface EventMessage {
  type: 'event';
  event: 'agent.start' | 'agent.thinking' | 'tool.call' | 'agent.complete';
  data: unknown;
}
```

### 3.3 Flujo de Mensajes

```mermaid
sequenceDiagram
    participant C as Cliente
    participant G as Gateway
    participant A as Agente
    participant L as LLM
    
    C->>G: WebSocket connect
    G-->>C: Connected
    
    C->>G: ChatRequest
    G->>A: Process message
    A->>G: Event: thinking
    G-->>C: Event: thinking
    
    A->>L: Generate response
    L-->>A: Response + tool calls
    
    alt Con tool calls
        A->>G: Event: tool.call
        G-->>C: Event: tool.call
        A->>A: Execute tools
    end
    
    A->>G: ChatResponse
    G-->>C: ChatResponse
```

---

## 4. API OpenAI-Compatible

### 4.1 Endpoint de Chat

```bash
# Chat completion
curl http://127.0.0.1:18789/v1/chat/completions \
  -H "Authorization: Bearer d91adb5e7091a088e3b1958e9dbd33f4686e7f21fef02844" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "zai/glm-4.5-air",
    "messages": [
      {"role": "user", "content": "Hola, ¿qué puedes hacer?"}
    ],
    "stream": true
  }'
```

### 4.2 Response Format

```json
{
  "id": "chatcmpl-abc123",
  "object": "chat.completion",
  "created": 1709508800,
  "model": "zai/glm-4.5-air",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "¡Hola! Soy el OPENCLAW-system..."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 15,
    "completion_tokens": 50,
    "total_tokens": 65
  }
}
```

### 4.3 Streaming

```javascript
// Streaming con Server-Sent Events
const response = await fetch('/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer ' + token,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    model: 'zai/glm-4.5-air',
    messages: [...],
    stream: true
  })
});

const reader = response.body.getReader();
while (true) {
  const { done, value } = await reader.read();
  if (done) break;
  
  const chunk = new TextDecoder().decode(value);
  // data: {"choices":[{"delta":{"content":"Hola"}}]}
  console.log(chunk);
}
```

---

## 5. Autenticación Multi-Modo

### 5.1 Modos de Autenticación

| Modo | Uso | Configuración |
|------|-----|---------------|
| **Token** | Default, simple | `auth.mode: "token"` |
| **API Key** | Integraciones | `auth.mode: "apikey"` |
| **OAuth** | Enterprise | `auth.mode: "oauth"` |

### 5.2 Configuración por Modo

```json
// Token mode (default)
{
  "auth": {
    "mode": "token",
    "token": "d91adb5e7091a088e3b1958e9dbd33f4686e7f21fef02844"
  }
}

// API Key mode
{
  "auth": {
    "mode": "apikey",
    "keys": ["sk-key1...", "sk-key2..."],
    "rateLimit": {
      "requests": 100,
      "windowMs": 60000
    }
  }
}

// OAuth mode
{
  "auth": {
    "mode": "oauth",
    "provider": "google",
    "clientId": "...",
    "clientSecret": "..."
  }
}
```

---

## 6. Comunicación Inter-Engranajes

### 6.1 Protocolo R-P-V

```typescript
// Patrón Solicitud-Proceso-Validación
interface MensajeRol {
  from: 'director' | 'ejecutor' | 'archivador';
  to: 'director' | 'ejecutor' | 'archivador' | 'todos';
  type: 'solicitud' | 'respuesta' | 'difusion';
  payload: unknown;
  correlationId: string;
  timestamp: number;
}

// Ejemplo: Director → Ejecutor
const solicitudAEjecutor: MensajeRol = {
  from: 'director',
  to: 'ejecutor',
  type: 'solicitud',
  payload: {
    action: 'execute_task',
    task: 'Leer archivo /workspace/data.txt'
  },
  correlationId: 'req-123',
  timestamp: Date.now()
};
```

### 6.2 Canales de Comunicación

```mermaid
graph LR
    D[Director] -->|Validar| E[Ejecutor]
    D -->|Consultar| A[Archivador]
    E -->|Reportar| D
    A -->|Contexto| D
    A -.->|Solo-lectura| E
```

### 6.3 Rate Limiting Inter-Roles

```typescript
const limitesTasaInterRoles = {
  director: {
    maxRequests: 100,
    windowMs: 60000
  },
  ejecutor: {
    maxRequests: 50,
    windowMs: 60000
  },
  archivador: {
    maxRequests: 200,
    windowMs: 60000
  }
};
```

---

## 7. Canales Externos

### 7.1 Canales Soportados (20+)

```typescript
const supportedChannels = [
  // Messaging
  'telegram', 'whatsapp', 'discord', 'slack',
  'signal', 'imessage', 'line', 'matrix',
  
  // Enterprise
  'msteams', 'mattermost', 'googlechat', 'feishu',
  
  // Social
  'twitter', 'twitch', 'nostr',
  
  // Regional
  'zalo', 'kakao', 'wechat',
  
  // Self-hosted
  'nextcloud-talk', 'synology-chat'
];
```

### 7.2 Configuración de Canal

```typescript
// src/channels/plugins/telegram/
const telegramConfig = {
  enabled: true,
  botToken: "${TELEGRAM_BOT_TOKEN}",
  allowFrom: ["@usuario"],
  commands: {
    prefix: "/",
    list: ["/help", "/status", "/new", "/reset"]
  },
  features: {
    markdown: true,
    photos: true,
    documents: true,
    voice: true
  }
};
```

---

## 8. Manejo de Concurrencia

### 8.1 Cola de Mensajes

```typescript
// src/auto-reply/reply/queue/
const queueConfig = {
  maxSize: 1000,
  concurrency: 5,
  timeout: 60000,
  retryAttempts: 3,
  retryDelay: 1000
};
```

### 8.2 Dispatcher

```mermaid
graph TB
    subgraph "MENSAJES ENTRANTES"
        M1[Mensaje 1]
        M2[Mensaje 2]
        M3[Mensaje 3]
    end
    
    subgraph "DISPATCHER"
        QUEUE[Cola de Mensajes]
        WORKERS[Pool de Ejecutores]
    end

    subgraph "PROCESAMIENTO"
        W1[Ejecutor 1]
        W2[Ejecutor 2]
        W3[Ejecutor 3]
    end
    
    M1 --> QUEUE
    M2 --> QUEUE
    M3 --> QUEUE
    
    QUEUE --> WORKERS
    WORKERS --> W1
    WORKERS --> W2
    WORKERS --> W3
```

---

## 9. Rate Limiting y Throttling

### 9.1 Configuración

```typescript
const rateLimitConfig = {
  global: {
    requestsPerMinute: 100,
    requestsPerHour: 1000
  },
  perUser: {
    requestsPerMinute: 20,
    requestsPerHour: 200
  },
  perChannel: {
    telegram: { requestsPerMinute: 30 },
    discord: { requestsPerMinute: 50 },
    whatsapp: { requestsPerMinute: 20 }
  }
};
```

### 9.2 Headers de Rate Limit

```http
HTTP/1.1 200 OK
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1709508800
```

---

## 10. Diagrama de Flujo de Mensajes

```mermaid
sequenceDiagram
    participant U as Usuario
    participant TG as Telegram
    participant GW as Gateway
    participant ORQ as Orquestador
    participant D as Director
    participant E as Ejecutor
    participant A as Archivador
    
    U->>TG: Envía mensaje
    TG->>GW: Webhook/Polling
    GW->>ORQ: Dispatch message
    
    ORQ->>D: Validar intención
    D->>A: Buscar contexto
    A-->>D: Contexto relevante

    D-->>ORQ: Plan validado
    ORQ->>E: Ejecutar plan
    
    alt Requiere tools
        E->>E: Ejecutar tools
        E->>A: Guardar resultado
    end
    
    E-->>ORQ: Resultado
    ORQ->>GW: Respuesta
    GW->>TG: Enviar mensaje
    TG-->>U: Recibe respuesta
```

---

## 11. Comandos de Gestión

```bash
# Estado del Gateway
openclaw gateway status

# Ver token
openclaw config get gateway.auth.token

# Generar nuevo token
openclaw doctor --generate-gateway-token

# Reiniciar Gateway
systemctl --user restart openclaw-gateway

# Ver logs
tail -f ~/.openclaw/logs/gateway.log

# Test de conexión
curl http://127.0.0.1:18789/health
```

---

## 12. Referencias Cruzadas

- **Integración OpenClaw:** [../02-INSTANCIAS/00-openclaw-integracion.md](../02-INSTANCIAS/00-openclaw-integracion.md)
- **Seguridad:** [../11-SEGURIDAD/00-seguridad.md](../11-SEGURIDAD/00-seguridad.md)
- **Daemon y Servicios:** [../01-SISTEMA/05-daemon-servicios.md](../01-SISTEMA/05-daemon-servicios.md)

---

**Documento:** Comunicación: Gateway y Protocolos
**Ubicación:** `docs/08-FLUJOS/00-comunicaciones.md`
**Versión:** 2.1.0
**Fecha:** 2026-03-09
