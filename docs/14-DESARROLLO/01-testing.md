# Testing y QA

**ID:** DOC-DES-TES-001
**Versión:** OPENCLAW-system v1.0
**Fecha:** 2026-03-09
**Estado:** Documentación Técnica

---

## 1. Estrategia de Testing

### 1.1 Pirámide de Testing

El OPENCLAW-system sigue la **pirámide de testing** clásica con capas especializadas:

```
          ┌─────────┐
          │   E2E   │  ← Pocos, lentos, caros
          │  5-10%  │
        ┌─┴─────────┴─┐
        │ Integration │  ← Moderados
        │    20-30%    │
      ┌─┴─────────────┴─┐
      │     Unit        │  ← Muchos, rápidos, baratos
      │     60-75%       │
      └─────────────────┘
```

| Tipo | Cobertura | Velocidad | Costo |
|------|-----------|-----------|-------|
| Unit | 60-75% | < 100ms | Bajo |
| Integration | 20-30% | 1-5s | Medio |
| E2E | 5-10% | 10s+ | Alto |

### 1.2 TDD (Test-Driven Development)

Aplicar TDD en lógica crítica:
1. **RED**: Escribir test que falla
2. **GREEN**: Código mínimo para pasar
3. **REFACTOR**: Mejorar manteniendo verde

### 1.3 Continuous Testing

Los tests se ejecutan automáticamente en:
- **Pre-commit**: Linting + unit tests
- **Pre-push**: Integration tests
- **CI/CD**: Suite completa + E2E

---

## 2. Unit Tests

### 2.1 Framework: Vitest

Vitest es el framework de testing principal, compatible con Vite y extremadamente rápido.

**Instalación:**

```bash
pnpm add -D vitest @vitest/ui
```

**Configuración (`vitest.config.ts`):**

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      exclude: ['node_modules/', 'dist/', '**/*.test.ts'],
      statements: 80,
      branches: 80,
      functions: 80,
      lines: 80
    }
  }
});
```

### 2.2 Convenciones de Archivos

| Patrón | Uso |
|--------|-----|
| `*.test.ts` | Unit tests |
| `*.spec.ts` | Especificaciones BDD |

### 2.3 Ejemplos de Tests Unitarios

**Test basico:**

```typescript
// director.test.ts
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { Director } from './director';
import type { DirectorConfig, Task } from './types';

describe('Director', () => {
  let director: Director;
  let mockConfig: DirectorConfig;

  beforeEach(() => {
    mockConfig = {
      name: 'test-director',
      model: 'openai:gpt-4',
      skills: []
    };
    director = new Director(mockConfig);
  });

  describe('delegate', () => {
    it('should delegate task to available ejecutor', async () => {
      const task: Task = { type: 'search', query: 'test query' };

      const result = await director.delegate(task);

      expect(result.success).toBe(true);
      expect(result.output).toBeDefined();
    });

    it('should throw EjecutorUnavailableError when no ejecutores', async () => {
      director.ejecutores.clear();

      await expect(director.delegate({ type: 'search' }))
        .rejects.toThrow('EjecutorUnavailableError');
    });

    it('should retry on transient failures', async () => {
      const failingEjecutor = vi.fn()
        .mockRejectedValueOnce(new Error('Network error'))
        .mockResolvedValueOnce({ success: true });

      director.ejecutores.set('ejecutor-1', failingEjecutor);

      const result = await director.delegate({ type: 'search' });

      expect(failingEjecutor).toHaveBeenCalledTimes(2);
      expect(result.success).toBe(true);
    });
  });

  describe('validateResponse', () => {
    it('should validate response schema', () => {
      const validResponse = { type: 'answer', content: 'test' };

      expect(() => director.validateResponse(validResponse))
        .not.toThrow();
    });

    it('should reject invalid response schema', () => {
      const invalidResponse = { type: 'invalid' };

      expect(() => director.validateResponse(invalidResponse))
        .toThrow('SchemaValidationError');
    });
  });
});
```

**Test con mocking:**

```typescript
// ejecutor.test.ts
import { describe, it, expect, vi, Mock } from 'vitest';
import { Ejecutor } from './ejecutor';
import { execInSandbox } from './sandbox';

vi.mock('./sandbox');

describe('Ejecutor', () => {
  describe('executeCommand', () => {
    it('should execute command in sandbox', async () => {
      const ejecutor = new Ejecutor({ name: 'test-ejecutor' });
      (execInSandbox as Mock).mockResolvedValue({
        stdout: 'success',
        stderr: '',
        exitCode: 0
      });

      const result = await ejecutor.executeCommand('ls -la');

      expect(execInSandbox).toHaveBeenCalledWith('ls -la');
      expect(result.stdout).toBe('success');
    });

    it('should handle sandbox errors gracefully', async () => {
      (execInSandbox as Mock).mockRejectedValue(new Error('Sandbox crashed'));

      await expect(ejecutor.executeCommand('rm -rf /'))
        .rejects.toThrow('SandboxError');
    });
  });
});
```

### 2.4 Mocking de Dependencias

**Mock de módulos:**

```typescript
// Mock de OpenAI
vi.mock('openai', () => ({
  OpenAI: vi.fn().mockImplementation(() => ({
    chat: {
      completions: {
        create: vi.fn().mockResolvedValue({
          choices: [{ message: { content: 'Mocked response' } }]
        })
      }
    }
  }))
}));
```

**Mock de variables de entorno:**

```typescript
vi.stubEnv('OPENAI_API_KEY', 'test-key-123');
```

---

## 3. Integration Tests

### 3.1 Configuración

Los tests de integración verifican la comunicación entre componentes.

**Patrón:** `*.integration.test.ts`

**Ejemplo - Comunicación R-P-V (Request-Process-Validate):**

```typescript
// triumvirate.integration.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Director } from './director';
import { Ejecutor } from './ejecutor';
import { Archivador } from './archivador';

describe('Triumvirate Integration', () => {
  let director: Director;
  let ejecutor: Ejecutor;
  let archivador: Archivador;

  beforeAll(async () => {
    director = new Director({ port: 3000 });
    ejecutor = new Ejecutor({ port: 3001 });
    archivador = new Archivador({ port: 3002 });
    
    await Promise.all([
      manager.start(),
      worker.start(),
      archivist.start()
    ]);
  });

  afterAll(async () => {
    await Promise.all([
      manager.stop(),
      worker.stop(),
      archivist.stop()
    ]);
  });

  it('should complete full R-P-V cycle', async () => {
    const request = { query: '¿Qué es OpenClaw?' };

    // 1. Director recibe y procesa
    const processed = await director.processRequest(request);
    expect(processed.task).toBeDefined();

    // 2. Ejecutor ejecuta
    const executed = await ejecutor.execute(processed.task);
    expect(executed.result).toBeDefined();

    // 3. Archivador valida y almacena
    const validated = await archivador.validateAndStore(executed);
    expect(validated.stored).toBe(true);

    // 4. Director consolida respuesta
    const response = await director.consolidate(validated);
    expect(response.content).toBeDefined();
  });

  it('should handle communication failures', async () => {
    await ejecutor.stop(); // Simular caída del ejecutor

    await expect(director.processRequest({ query: 'test' }))
      .rejects.toThrow('EjecutorUnavailable');

    await ejecutor.start(); // Restaurar
  });
});
```

### 3.2 Testing de Bases de Datos

```typescript
// memory.integration.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { MemoryEngine } from './memory';
import { SQLiteVecStore } from './vector-store';

describe('Memory Integration', () => {
  let memory: MemoryEngine;

  beforeEach(async () => {
    memory = new MemoryEngine({
      store: new SQLiteVecStore(':memory:')
    });
    await memory.initialize();
  });

  it('should store and retrieve memories', async () => {
    const content = 'OpenClaw es un framework de agentes';
    
    await memory.store({ content, metadata: { source: 'docs' } });
    
    const results = await memory.search('framework agentes');
    expect(results).toHaveLength(1);
    expect(results[0].content).toContain('OpenClaw');
  });

  it('should perform semantic search', async () => {
    await memory.storeBatch([
      { content: 'El Ejecutor ejecuta comandos' },
      { content: 'El Director orquesta tareas' },
      { content: 'El Archivador gestiona memoria' }
    ]);

    const results = await memory.semanticSearch('quien ejecuta', { topK: 2 });

    expect(results[0].content).toContain('Ejecutor');
  });
});
```

---

## 4. E2E Tests

### 4.1 Framework: Playwright

```bash
pnpm add -D @playwright/test
npx playwright install
```

**Configuración (`playwright.config.ts`):**

```typescript
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  timeout: 30000,
  retries: 2,
  use: {
    baseURL: 'http://localhost:18789',
    screenshot: 'only-on-failure'
  },
  projects: [
    { name: 'telegram', testMatch: /telegram.*\.e2e\.test\.ts/ },
    { name: 'slack', testMatch: /slack.*\.e2e\.test\.ts/ }
  ]
});
```

### 4.2 Ejemplo E2E - Canal Telegram

```typescript
// telegram.e2e.test.ts
import { test, expect } from '@playwright/test';

test.describe('Telegram Channel E2E', () => {
  test.beforeEach(async ({ request }) => {
    // Verificar que el gateway está activo
    const health = await request.get('/health');
    expect(health.ok()).toBeTruthy();
  });

  test('should receive and respond to message', async ({ request }) => {
    // Simular mensaje entrante de Telegram
    const response = await request.post('/webhook/telegram', {
      data: {
        update_id: 12345,
        message: {
          message_id: 1,
          from: { id: 111, first_name: 'Test' },
          chat: { id: 111, type: 'private' },
          text: '¿Qué es OPENCLAW-system?'
        }
      }
    });

    expect(response.ok()).toBeTruthy();
    
    const body = await response.json();
    expect(body.response).toBeDefined();
    expect(body.response.content).toContain('OPENCLAW-system');
  });

  test('should handle rate limiting', async ({ request }) => {
    const requests = Array(10).fill(null).map(() =>
      request.post('/webhook/telegram', {
        data: { message: { text: 'test' } }
      })
    );

    const responses = await Promise.all(requests);
    const rateLimited = responses.filter(r => r.status() === 429);
    
    expect(rateLimited.length).toBeGreaterThan(0);
  });
});
```

---

## 5. Regression Tests

### 5.1 Convenciones

Los tests de regresión previenen que bugs reportados vuelvan a ocurrir.

**Patrón:** `*.regression.test.ts` con numeración secuencial.

### 5.2 Ejemplo

```typescript
// 001-memory-leak-worker.regression.test.ts
import { describe, it, expect } from 'vitest';

/**
 * BUG #45: Memory leak en Ejecutor tras 1000 iteraciones
 *
 * Problema: El ejecutor no liberaba referencias a tareas completadas,
 * causando crecimiento ilimitado de memoria.
 *
 * Solucion: Implementar cleanup automatico cada 100 tareas.
 */
describe('Regression: Memory Leak in Ejecutor', () => {
  it('should not leak memory after 1000 tasks', async () => {
    const ejecutor = new Ejecutor({ cleanupInterval: 100 });
    const initialMemory = process.memoryUsage().heapUsed;

    // Ejecutar 1000 tareas
    for (let i = 0; i < 1000; i++) {
      await ejecutor.execute({ type: 'test', id: i });
    }

    const finalMemory = process.memoryUsage().heapUsed;
    const growth = (finalMemory - initialMemory) / 1024 / 1024; // MB

    // El crecimiento no debe superar 50MB
    expect(growth).toBeLessThan(50);
  });
});
```

---

## 6. Performance Tests

### 6.1 Load Testing con k6

```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },  // Ramp up
    { duration: '1m', target: 20 },   // Stable
    { duration: '30s', target: 0 },   // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% < 500ms
  },
};

export default function () {
  const res = http.post('http://localhost:18789/webhook/telegram', {
    message: { text: 'test query' }
  });

  check(res, {
    'status 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });

  sleep(1);
}
```

### 6.2 Benchmarking con Vitest

```typescript
// benchmark.test.ts
import { bench, describe } from 'vitest';
import { MemoryEngine } from './memory';

describe('Memory Engine benchmarks', () => {
  let memory: MemoryEngine;

  bench('semantic search', async () => {
    await memory.semanticSearch('test query', { topK: 10 });
  });

  bench('store memory', async () => {
    await memory.store({ content: 'test content' });
  });
});
```

---

## 7. CI/CD para Tests

### 7.1 GitHub Actions

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: pnpm/action-setup@v2
        with:
          version: 10.23.0
      
      - uses: actions/setup-node@v4
        with:
          node-version: 23
          cache: 'pnpm'
      
      - run: pnpm install
      
      - name: Lint
        run: pnpm lint
      
      - name: Unit Tests
        run: pnpm test:coverage
      
      - name: Integration Tests
        run: pnpm test:integration
      
      - name: Upload Coverage
        uses: codecov/codecov-action@v4
```

---

## 8. Reports y Métricas

### 8.1 Cobertura de Código

```bash
# Generar reporte de cobertura
pnpm test:coverage

# Ver reporte HTML
open coverage/index.html
```

### 8.2 Métricas Clave

| Métrica | Objetivo | Alerta |
|---------|----------|--------|
| Cobertura | ≥ 80% | < 70% |
| Tiempo de test | < 30s | > 60s |
| Flaky tests | 0% | > 1% |

---

## 9. Referencias

- [Guía de Desarrollo](./00-guia-desarrollo.md)
- [Depuración](./04-depuracion.md)
- [Vitest Docs](https://vitest.dev)
- [Playwright Docs](https://playwright.dev)

---

**Última actualización:** 2026-03-09  
**Mantenido por:** Equipo de QA OPENCLAW-system
