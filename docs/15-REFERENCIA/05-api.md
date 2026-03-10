# Referencia de API

**ID:** DOC-REF-API-001
**Versión:** 1.0.0
**Fecha:** 2026-03-10
**Base URL:** `http://localhost:18789`

---

## Overview

The OPENCLAW API provides programmatic access to the multi-agent system. All requests are authenticated and responses are in JSON format.

---

## Authentication

### Token Authentication

```http
Authorization: Bearer <your-token>
```

### Obtaining a Token

```http
POST /auth/token
Content-Type: application/json

{
  "client_id": "your-client-id",
  "client_secret": "your-client-secret"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

---

## Endpoints

### Execute Request

Execute a request through the multi-agent system.

```http
POST /api/v1/execute
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "namespace": "/dev",
  "request": "Create a REST API with Express for user management",
  "context": {
    "project_path": "~/projects/myapp",
    "language": "typescript"
  },
  "options": {
    "timeout": 60000,
    "require_approval": false,
    "validate_output": true
  }
}
```

**Response:**
```json
{
  "request_id": "req_abc123",
  "status": "completed",
  "namespace": "/dev",
  "specialist": "DEV-001",
  "result": {
    "output": "Created files...",
    "files": [
      {
        "path": "src/routes/users.ts",
        "action": "created",
        "size": 1234
      }
    ],
    "metrics": {
      "execution_time_ms": 4532,
      "validation_passed": true,
      "consensus_achieved": true
    }
  },
  "metadata": {
    "manager_model": "openclaw-llama32",
    "worker_model": "openclaw-llama32",
    "timestamp": "2026-03-09T12:00:00Z"
  }
}
```

### Get Request Status

```http
GET /api/v1/requests/{request_id}
Authorization: Bearer <token>
```

**Response:**
```json
{
  "request_id": "req_abc123",
  "status": "in_progress",
  "progress": {
    "stage": "worker_execution",
    "percent": 60,
    "message": "Generating code..."
  }
}
```

### List Specialists

```http
GET /api/v1/specialists
Authorization: Bearer <token>
```

**Response:**
```json
{
  "specialists": [
    {
      "id": "DEV-001",
      "name": "DEV Unit",
      "namespace": "/dev",
      "chief": "cengo",
      "status": "active",
      "skills_count": 45
    },
    {
      "id": "INFRA-001",
      "name": "INFRA Unit",
      "namespace": "/infra",
      "chief": "cengo",
      "status": "active",
      "skills_count": 38
    }
  ],
  "total": 9
}
```

### Get Specialist Details

```http
GET /api/v1/specialists/{specialist_id}
Authorization: Bearer <token>
```

**Response:**
```json
{
  "id": "DEV-001",
  "name": "DEV Unit",
  "namespace": "/dev",
  "version": "1.0.0",
  "chief": "cengo",
  "status": "active",
  "skills": {
    "languages": ["typescript", "python", "rust", "go", "java"],
    "frameworks": ["react", "vue", "node", "django", "fastapi"],
    "databases": ["postgresql", "mongodb", "redis"],
    "devops": ["docker", "kubernetes", "terraform"]
  },
  "metrics": {
    "total_requests": 1234,
    "success_rate": 0.95,
    "avg_response_time_ms": 45000
  }
}
```

### Get Metrics

```http
GET /api/v1/metrics
Authorization: Bearer <token>
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `specialist_id` | string | Filter by specialist |
| `start_date` | ISO8601 | Start date |
| `end_date` | ISO8601 | End date |
| `interval` | string | hour, day, week |

**Response:**
```json
{
  "period": {
    "start": "2026-03-01T00:00:00Z",
    "end": "2026-03-09T23:59:59Z"
  },
  "summary": {
    "total_requests": 5678,
    "success_rate": 0.94,
    "avg_response_time_ms": 42000,
    "validation_pass_rate": 0.91
  },
  "by_specialist": [
    {
      "specialist_id": "DEV-001",
      "requests": 2345,
      "success_rate": 0.96
    }
  ],
  "by_namespace": [
    {
      "namespace": "/dev",
      "requests": 2345,
      "success_rate": 0.96
    }
  ]
}
```

### Memory Operations

#### Search Memory

```http
POST /api/v1/memory/search
Authorization: Bearer <token>
Content-Type: application/json

{
  "query": "express API authentication",
  "namespace": "/dev",
  "limit": 10,
  "min_relevance": 0.7
}
```

**Response:**
```json
{
  "results": [
    {
      "id": "mem_xyz789",
      "content": "JWT authentication implementation...",
      "relevance": 0.92,
      "timestamp": "2026-03-08T15:30:00Z",
      "metadata": {
        "task_type": "code_generation",
        "languages": ["typescript"]
      }
    }
  ],
  "total": 5
}
```

#### Save to Memory

```http
POST /api/v1/memory/save
Authorization: Bearer <token>
Content-Type: application/json

{
  "namespace": "/dev",
  "content": "Learned pattern: Repository pattern for data access",
  "metadata": {
    "task_type": "refactoring",
    "pattern": "repository"
  },
  "tags": ["design-pattern", "data-access"]
}
```

---

## Error Responses

### Error Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid namespace specified",
    "details": {
      "field": "namespace",
      "allowed_values": ["/dev", "/infra", "/hosteleria", "..."]
    }
  },
  "request_id": "req_abc123"
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `AUTHENTICATION_ERROR` | 401 | Invalid or expired token |
| `AUTHORIZATION_ERROR` | 403 | Insufficient permissions |
| `VALIDATION_ERROR` | 400 | Invalid request body |
| `NOT_FOUND` | 404 | Resource not found |
| `TIMEOUT_ERROR` | 408 | Request timed out |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

---

## Rate Limiting

| Endpoint | Limit | Window |
|----------|-------|--------|
| `/execute` | 60 | 1 minute |
| `/specialists` | 100 | 1 minute |
| `/metrics` | 30 | 1 minute |
| `/memory/*` | 100 | 1 minute |

### Rate Limit Headers

```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1709992800
```

---

## WebSocket API

### Connection

```javascript
const ws = new WebSocket('ws://localhost:18789/ws');

ws.onopen = () => {
  ws.send(JSON.stringify({
    type: 'authenticate',
    token: 'your-token'
  }));
};
```

### Execute with Streaming

```javascript
ws.send(JSON.stringify({
  type: 'execute',
  namespace: '/dev',
  request: 'Create API endpoints',
  stream: true
}));

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);

  switch (data.type) {
    case 'progress':
      console.log(`Progress: ${data.percent}%`);
      break;
    case 'output':
      console.log('Output chunk:', data.chunk);
      break;
    case 'complete':
      console.log('Final result:', data.result);
      break;
    case 'error':
      console.error('Error:', data.error);
      break;
  }
};
```

---

## SDK Examples

### Python

```python
from openclaw import Client

client = Client(token="your-token")

# Execute request
result = client.execute(
    namespace="/dev",
    request="Create REST API with Express",
    context={"project_path": "~/projects/myapp"}
)

print(result.output)
print(result.files)
```

### JavaScript/TypeScript

```typescript
import { OpenClawClient } from '@openclaw/sdk';

const client = new OpenClawClient({ token: 'your-token' });

const result = await client.execute({
  namespace: '/dev',
  request: 'Create REST API with Express',
  context: { projectPath: '~/projects/myapp' }
});

console.log(result.output);
console.log(result.files);
```

---

## OpenAPI Specification

Full OpenAPI 3.0 specification available at:

```
GET /api/openapi.json
```

Swagger UI available at:

```
GET /docs/api
```

---

**Documento:** Referencia de API
**Ubicación:** `docs/15-REFERENCIA/05-api.md`
**Versión:** 1.0.0
**Fecha:** 2026-03-10
