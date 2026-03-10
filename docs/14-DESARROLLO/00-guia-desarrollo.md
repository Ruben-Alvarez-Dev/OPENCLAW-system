# Guía para Desarrolladores

**ID:** DOC-DES-GUI-001
**Versión:** OPENCLAW-system v1.0
**Fecha:** 2026-03-09
**Estado:** Documentación Técnica

---

## 1. Configuración del Entorno de Desarrollo

### 1.1 Requisitos Previos

| Componente | Versión Mínima | Recomendada |
|-----------|---------------|-------------|
| **Node.js** | v20.x | v23.x (ARM64) |
| **pnpm** | v9.x | v10.23.0 |
| **Git** | v2.x | Latest |
| **Docker** | v24.x | Latest (para sandbox) |

**Instalación de dependencias del sistema:**

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y build-essential python3 curl git

# macOS (via Homebrew)
brew install node pnpm git
```

### 1.2 Setup del Repositorio Local

```bash
# Clonar e instalar
git clone https://github.com/tu-org/openclaw-system.git
cd openclaw-system
pnpm install

# CRÍTICO: Configurar PNPM_HOME para Skills
pnpm setup && source ~/.bashrc

# Build core-only (evita errores de dependencias)
node scripts/tsdown-build.mjs
npm link
```

### 1.3 Configuración de VSCode

**Extensiones recomendadas:**
- ESLint, Prettier
- TypeScript Nightly
- Tailwind CSS IntelliSense

**Launch configuration (`.vscode/launch.json`):**

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Director",
      "runtimeExecutable": "pnpm",
      "runtimeArgs": ["start:dev:director"],
      "console": "integratedTerminal"
    },
    {
      "type": "node",
      "request": "attach",
      "name": "Attach to PM2 Director",
      "port": 9229,
      "restart": true
    }
  ]
}
```

---

## 2. Flujo de Trabajo de Desarrollo

### 2.1 Branching Strategy (Git Flow)

```
main (producción)
  └── develop (integración)
        ├── feature/nuevo-skill
        ├── bugfix/memory-leak
        └── release/v1.1.0
```

**Nomenclatura de ramas:**

| Prefijo | Uso | Ejemplo |
|---------|-----|---------|
| `feature/` | Nuevas funcionalidades | `feature/mcp-integration` |
| `bugfix/` | Corrección de bugs | `bugfix/worker-crash` |
| `hotfix/` | Parches urgentes | `hotfix/gateway-down` |
| `release/` | Preparación de releases | `release/v1.2.0` |

### 2.2 Code Review Process

**Reglas obligatorias:**
1. Mínimo 1 aprobación
2. Tests pasando en CI/CD
3. Cobertura ≥ 80%
4. Sin conflictos con rama base
5. Linting sin errores

**Checklist de revisión:**

```markdown
- [ ] Código sigue convenciones del proyecto
- [ ] Tests añadidos/actualizados
- [ ] Documentación actualizada
- [ ] Sin console.logs o código comentado
- [ ] Type annotations completas
```

### 2.3 Commits Atómicos (Conventional Commits)

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Tipos permitidos:**

| Tipo | Uso | Ejemplo |
|------|-----|---------|
| `feat` | Nueva funcionalidad | `feat(manager): add MCP support` |
| `fix` | Bug fix | `fix(worker): sandbox leak` |
| `docs` | Documentación | `docs(api): update endpoints` |
| `refactor` | Refactorización | `refactor(archivist): optimize RAG` |
| `test` | Tests | `test(manager): add delegation tests` |
| `perf` | Rendimiento | `perf(gateway): reduce latency` |

### 2.4 Testing Antes de Commits

```bash
# Ejecutar siempre antes de commit
pnpm lint && pnpm test && pnpm typecheck
```

---

## 3. Estructura del Código

### 3.1 Organización de Módulos

```
src/
├── agents/           # Motor de agentes
│   ├── director/     # Director (orquestador)
│   ├── ejecutor/     # Ejecutor (procesamiento)
│   ├── archivador/   # Archivador (memoria)
│   └── sandbox/      # Docker sandbox
├── channels/         # Plugins de canales (20+)
├── memory/           # Sistema RAG
├── browser/          # Automatización Playwright
├── cli/              # Comandos CLI
├── config/           # Gestión de config (Zod)
├── cron/             # Tareas programadas
└── gateway/          # API Gateway
```

### 3.2 Nomenclatura de Archivos

| Tipo | Patrón | Ejemplo |
|------|--------|---------|
| Clases | PascalCase | `AgentManager.ts` |
| Funciones | camelCase | `processRequest.ts` |
| Tests unitarios | `*.test.ts` | `manager.test.ts` |
| Tests integración | `*.integration.test.ts` | `rag.integration.test.ts` |
| Tests E2E | `*.e2e.test.ts` | `telegram.e2e.test.ts` |
| Tests regresión | `*.regression.test.ts` | `001-leak.regression.test.ts` |

### 3.3 Type Annotations

**Siempre tipar explícitamente:**

```typescript
// ✅ Correcto
interface AgentConfig {
  name: string;
  model: LLMProvider;
  skills: Skill[];
}

function createAgent(config: AgentConfig): Agent {
  // ...
}

// ❌ Evitar any
function process(data: any): any { ... }
```

**tsconfig.json strict mode:**

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true
  }
}
```

---

## 4. Debugging Local

### 4.1 Logs de Depuración

```typescript
import { logger } from '@openclaw/core';

logger.debug('Variable x:', { x });
logger.info('Procesando solicitud');
logger.warn('Rate limit alcanzado');
logger.error('Error en ejecutor', error);
```

**Ver logs en tiempo real:**

```bash
pm2 logs sis-director --lines 100
pm2 logs | grep "ERROR"
```

### 4.2 Breakpoints en VSCode

1. Click en margen izquierdo para breakpoint
2. F5 para iniciar debugging
3. Inspeccionar variables en panel izquierdo

**Debug con PM2:**

```bash
pm2 start ecosystem.config.js --node-args="--inspect=9229"
# Luego attach desde VSCode
```

---

## 5. Testing Local

### 5.1 Tests Unitarios (Vitest)

```bash
pnpm test                    # Todos los tests
pnpm test manager.test.ts    # Test específico
pnpm test:coverage           # Con cobertura
pnpm test:watch              # Watch mode
```

**Ejemplo de test unitario:**

```typescript
import { describe, it, expect, vi } from 'vitest';
import { Director } from './director';

describe('Director', () => {
  it('should delegate task to ejecutor', async () => {
    const director = new Director(mockConfig);
    const result = await director.delegate({ type: 'search' });
    expect(result.success).toBe(true);
  });

  it('should handle ejecutor unavailable', async () => {
    const director = new Director({ ...mockConfig, ejecutores: [] });
    await expect(director.delegate(task))
      .rejects.toThrow(EjecutorUnavailableError);
  });
});
```

### 5.2 Tests de Integración

```bash
pnpm test:integration
```

### 5.3 Tests E2E (Playwright)

```bash
pnpm test:e2e
```

---

## 6. Contribución al Proyecto

### 6.1 Pull Requests

**Proceso:**
1. Crear rama desde `develop`
2. Desarrollar con tests
3. Ejecutar `pnpm lint && pnpm test`
4. Crear PR con descripción completa
5. Esperar code review
6. Squash and merge

**Template de PR:**

```markdown
## Descripción
[Breve descripción]

## Tipo de cambio
- [ ] Bug fix / Feature / Breaking change / Docs

## Checklist
- [ ] Tests añadidos
- [ ] Documentación actualizada
- [ ] Todos los tests pasan
```

---

## 7. Recursos

### Documentación Interna
- [Arquitectura](../01-SISTEMA/00-arquitectura-maestra.md)
- [Testing y QA](./01-testing.md)
- [Ciclo de Vida](./02-ciclo-vida.md)
- [Extensibilidad](./03-extensibilidad.md)
- [Troubleshooting](./04-depuracion.md)

### Recursos Externos
- [OpenClaw Docs](https://openclaw.ai/docs)
- [Vitest](https://vitest.dev)
- [Playwright](https://playwright.dev)
- [PM2](https://pm2.keymetrics.io/docs)

---

## 8. Checklist de Desarrollo

```markdown
## Pre-Development
- [ ] Revisar issues relacionados
- [ ] Crear rama con nombre correcto

## During Development
- [ ] Commits atómicos
- [ ] Tests escritos
- [ ] Type annotations completas

## Pre-Commit
- [ ] `pnpm lint` pasa
- [ ] `pnpm test` pasa
- [ ] `pnpm typecheck` pasa

## Pre-Merge
- [ ] PR creado con descripción
- [ ] Code review aprobado
- [ ] CI/CD pasa
```

---

**Última actualización:** 2026-03-09  
**Mantenido por:** Equipo de Desarrollo OPENCLAW-system
