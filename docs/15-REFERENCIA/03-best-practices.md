# Best Practices

**ID:** DOC-REF-PRA-001
**Versión:** 1.1
**Última actualización:** 2026-03-10
**Estado:** Referencia Oficial

---

## Desarrollo

### TypeScript

| Práctica | Descripción |
|----------|-------------|
| Strict mode | `strict: true` en tsconfig.json |
| Tipado explícito | Evitar `any`, usar tipos específicos |
| Interfaces | Preferir interfaces sobre types para objetos |
| Enums | Usar string enums para claridad |
| Async/await | Evitar .then() chains |

```typescript
// ✅ Correcto
interface AgentConfig {
  name: string;
  model: string;
  enabled: boolean;
}

// ❌ Incorrecto
const config: any = { name: "agent" };
```

### Principios SOLID

| Principio | Aplicación |
|-----------|------------|
| **S**ingle Responsibility | Una clase, una responsabilidad |
| **O**pen/Closed | Abierto a extensión, cerrado a modificación |
| **L**iskov Substitution | Subclases sustituibles |
| **I**nterface Segregation | Interfaces específicas |
| **D**ependency Inversion | Depender de abstracciones |

### DRY y SRP

| Principio | Descripción |
|-----------|-------------|
| DRY | Don't Repeat Yourself - extraer lógica común |
| SRP | Single Responsibility Principle - una función, un propósito |
| KISS | Keep It Simple, Stupid - simplicidad sobre complejidad |
| YAGNI | You Aren't Gonna Need It - no sobre-ingeniar |

---

## Configuración

### Config-as-Code

```yaml
# config/default.yaml
app:
  name: openclaw-system
  version: 2.1.0

gateway:
  host: 127.0.0.1
  port: 18789

agents:
  defaultModel: claude-3-5-sonnet
  maxConcurrent: 10
```

### Variables de Entorno

```bash
# .env.example
NODE_ENV=production
LOG_LEVEL=info

# API Keys
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Database
DATABASE_URL=postgresql://...
```

### Gestión de Secretos

| Método | Uso | Seguridad |
|--------|-----|-----------|
| `.env` | Desarrollo | ⚠️ No commitear |
| Vault | Producción | ✅ Recomendado |
| AWS Secrets | Cloud | ✅ Recomendado |
| Doppler | SaaS | ✅ Recomendado |

### Validación con Zod

```typescript
import { z } from 'zod';

const ConfigSchema = z.object({
  gateway: z.object({
    host: z.string().default('127.0.0.1'),
    port: z.number().int().min(1).max(65535).default(18789),
  }),
  agents: z.object({
    defaultModel: z.string(),
    maxConcurrent: z.number().int().positive().default(10),
  }),
});

type Config = z.infer<typeof ConfigSchema>;
```

---

## Seguridad

### Principios Fundamentales

| Principio | Descripción |
|-----------|-------------|
| Least Privilege | Mínimos permisos necesarios |
| Defense in Depth | Múltiples capas de seguridad |
| Zero Trust | No confiar por defecto |
| Fail Secure | Fallo seguro en errores |

### Sandboxing

```yaml
sandbox:
  enabled: true
  driver: docker  # docker | gvisor | kata
  timeout: 30000
  memoryLimit: 512M
  networkAccess: false
```

### Validación de Input

```typescript
// Siempre validar input externo
const UserInputSchema = z.object({
  message: z.string().max(10000),
  channel: z.enum(['slack', 'discord', 'telegram']),
  userId: z.string().uuid(),
});
```

### Rate Limiting

```typescript
const rateLimiter = {
  windowMs: 60 * 1000,  // 1 minuto
  maxRequests: 100,     // máximo 100 requests
  keyGenerator: (req) => req.userId,
};
```

---

## Testing

### Pirámide de Testing

```
                    ┌─────────┐
                   │   E2E   │  (Pocos, lentos)
                  └───────────┘
                 └─────────────┘
                │ Integration │  (Algunos)
               └───────────────┘
              └─────────────────┘
             │    Unit Tests    │  (Muchos, rápidos)
            └───────────────────┘
```

### TDD Workflow

```
🔴 RED → Escribir test que falla
🟢 GREEN → Código mínimo para pasar
🔵 REFACTOR → Mejorar manteniendo tests verdes
```

### Coverage

| Tipo | Mínimo | Objetivo |
|------|--------|----------|
| Statements | 80% | 90%+ |
| Branches | 75% | 85%+ |
| Functions | 80% | 90%+ |
| Lines | 80% | 90%+ |

### Ejemplo Vitest

```typescript
import { describe, it, expect } from 'vitest';

describe('Agent', () => {
  it('should process message correctly', async () => {
    const agent = new Agent(config);
    const result = await agent.process('Hello');
    expect(result).toBeDefined();
    expect(result.success).toBe(true);
  });
});
```

---

## Operaciones

### Logs Estructurados

```typescript
import { logger } from './logger';

logger.info('Agent started', {
  agentId: 'archivist',
  model: 'claude-3-5-sonnet',
  timestamp: new Date().toISOString(),
});
```

### Observabilidad

| Componente | Herramienta |
|------------|-------------|
| Logs | Pino / Winston |
| Métricas | Prometheus |
| Tracing | OpenTelemetry |
| Dashboards | Grafana |

### Backup

```yaml
backup:
  schedule: "0 2 * * *"  # Diario a las 2am
  retention: 30d
  destination: s3://backups/openclaw-system/
  includes:
    - ./data/
    - ./config/
```

### Incident Management

| Fase | Acción |
|------|--------|
| Detección | Alertas automáticas |
| Respuesta | Runbooks documentados |
| Resolución | Escalamiento definido |
| Post-mortem | Análisis sin culpar |

---

## Escalabilidad

### Stateless Design

```typescript
// ✅ Stateless - escalable
class AgentHandler {
  async process(message: Message, context: Context) {
    // Estado en contexto, no en instancia
  }
}

// ❌ Stateful - no escalable
class AgentHandler {
  private state: Map<string, any> = new Map();
}
```

### Escalado

| Tipo | Uso | Ejemplo |
|------|-----|---------|
| Horizontal | Más instancias | PM2 cluster mode |
| Vertical | Más recursos | Aumentar RAM/CPU |

### Load Balancing

```yaml
loadBalancer:
  algorithm: round-robin  # round-robin | least-connections | ip-hash
  healthCheck:
    interval: 30s
    timeout: 5s
```

### Caching

```typescript
const cache = {
  ttl: 3600,  // 1 hora
  maxKeys: 10000,
  strategy: 'lru',
};
```

### Connection Pooling

```typescript
const pool = {
  min: 2,
  max: 10,
  idleTimeout: 30000,
  acquireTimeout: 5000,
};
```

---

## Mantenimiento

### Actualizaciones

| Frecuencia | Tipo |
|------------|------|
| Semanal | Patches de seguridad |
| Mensual | Minor versions |
| Trimestral | Major versions (con testing) |

### Staging

```yaml
environments:
  - development
  - staging     # Testing completo
  - production
```

### Rollback

```bash
# Rollback PM2
pm2 rollback openclaw-system

# Rollback Docker
docker service rollback openclaw-system_agent
```

### CHANGELOG

```markdown
## [1.0.1] - 2026-03-09
### Fixed
- Memory leak in WebSocket handler

### Added
- New Slack channel adapter

### Changed
- Updated Claude model to 3.5 Sonnet
```

---

## Anti-Patterns a Evitar

| Anti-Pattern | Problema | Solución |
|--------------|----------|----------|
| Spaghetti code | Difícil mantenimiento | Modularizar |
| God object | Responsabilidades mezcladas | SRP |
| Premature optimization | Complejidad innecesaria | Optimizar cuando sea necesario |
| Copy-paste programming | Duplicación | DRY |
| Magic numbers | Código ilegible | Constantes con nombre |
| Hardcoded config | Inflexibilidad | Config externa |
| Swallowing errors | Debugging difícil | Loggear errores |

---

## Checklist de Best Practices

### Desarrollo
- [ ] TypeScript strict mode habilitado
- [ ] Tipado explícito (sin `any`)
- [ ] Principios SOLID aplicados
- [ ] Código documentado
- [ ] Sin código comentado

### Testing
- [ ] Tests unitarios >80% coverage
- [ ] Tests de integración en flujos críticos
- [ ] Tests E2E en happy paths
- [ ] CI/CD configurado

### Seguridad
- [ ] Input validation en todos los endpoints
- [ ] Rate limiting implementado
- [ ] Secretos en Vault/no hardcoded
- [ ] Sandboxing habilitado

### Configuración
- [ ] Variables de entorno documentadas
- [ ] Validación con Zod
- [ ] Defaults sensatos
- [ ] Config por ambiente

### Operaciones
- [ ] Logs estructurados
- [ ] Métricas expuestas
- [ ] Alertas configuradas
- [ ] Backups automáticos
- [ ] Runbooks documentados

---

## Referencias

| Tema | Fuente |
|------|--------|
| TypeScript Best Practices | https://typescript.tv/best-practices/ |
| SOLID Principles | https://en.wikipedia.org/wiki/SOLID |
| 12-Factor App | https://12factor.net/ |
| OWASP Top 10 | https://owasp.org/www-project-top-ten/ |
| Google SRE | https://sre.google/books/ |

---

> **Ver también:** [02-architectures.md](02-architectures.md) | [04-glosario.md](04-glosario.md)
