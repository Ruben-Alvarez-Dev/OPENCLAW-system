# Configuración de APIs Cloud - OPENCLAW Personal

**ID:** DOC-PER-CFG-001
**Versión:** 1.0
**Fecha:** 2026-03-10

---

## Resumen

Configuración de las suscripciones AI disponibles para OPENCLAW-system.

---

## APIs Disponibles

### Z.ai (Principal)

| Aspecto | Valor |
|---------|-------|
| Plan | Coding Plan Máximo |
| Crédito | Alto |
| Mejor para | Desarrollo principal, arquitectura |
| Modelos | glm-5, glm-4.7, glm-4.6, glm-4.5 |

```bash
# Configuración
export ZAI_API_KEY="tu_api_key"
export ZAI_API_BASE="https://api.z.ai/v1"
```

### Minimax (Backup)

| Aspecto | Valor |
|---------|-------|
| Plan | Coding Plan 20€/mes |
| Crédito | Medio |
| Mejor para | Alternativa, backup |
| Modelos | abab6.5-chat |

```bash
export MINIMAX_API_KEY="tu_api_key"
export MINIMAX_API_BASE="https://api.minimax.chat/v1"
```

### Mistral (Especializado)

| Aspecto | Valor |
|---------|-------|
| Plan | Premium |
| Crédito | Medio |
| Mejor para | Código especializado |
| Modelos | codestral, mistral-large |

```bash
export MISTRAL_API_KEY="tu_api_key"
export MISTRAL_API_BASE="https://api.mistral.ai/v1"
```

### OpenAI ChatGPT (Puntual)

| Aspecto | Valor |
|---------|-------|
| Plan | Plus 9€/mes |
| Crédito | Limitado |
| Mejor para | Consultas usuario |
| Modelos | gpt-4o, gpt-4-turbo |

```bash
export OPENAI_API_KEY="tu_api_key"
```

---

## Proveedor Unificado

```javascript
// src/providers/unified.js
import { createOpenAICompatible } from '@ai-sdk/openai-compatible';

const providers = {
  zai: createOpenAICompatible({
    name: 'zai',
    apiBase: process.env.ZAI_API_BASE,
    apiKey: process.env.ZAI_API_KEY,
  }),

  minimax: createOpenAICompatible({
    name: 'minimax',
    apiBase: process.env.MINIMAX_API_BASE,
    apiKey: process.env.MINIMAX_API_KEY,
  }),

  mistral: createOpenAICompatible({
    name: 'mistral',
    apiBase: process.env.MISTRAL_API_BASE,
    apiKey: process.env.MISTRAL_API_KEY,
  }),

  openai: createOpenAICompatible({
    name: 'openai',
    apiBase: 'https://api.openai.com/v1',
    apiKey: process.env.OPENAI_API_KEY,
  }),
};

// Modelos disponibles por proveedor
export const models = {
  // Z.ai
  'glm-5': providers.zai('glm-5'),
  'glm-4.7': providers.zai('glm-4.7'),
  'glm-4.6': providers.zai('glm-4.6'),

  // Minimax
  'abab6.5': providers.minimax('abab6.5-chat'),

  // Mistral
  'codestral': providers.mistral('codestral-latest'),
  'mistral-large': providers.mistral('mistral-large-latest'),

  // OpenAI
  'gpt-4o': providers.openai('gpt-4o'),
  'gpt-4-turbo': providers.openai('gpt-4-turbo'),
};

// Router por tipo de tarea
export function selectModel(tarea) {
  const routing = {
    'arquitectura': 'glm-5',
    'codigo_complejo': 'glm-5',
    'codigo_diario': 'glm-4.7',
    'consulta_rapida': 'glm-4.6',
    'especializado': 'codestral',
    'usuario': 'gpt-4o',
    'fallback': 'abab6.5',
  };

  return models[routing[tarea]] || models[routing.fallback];
}

export default models;
```

---

## Matriz de Uso Óptimo

| Tarea | Primario | Secundario | Terciario |
|-------|----------|------------|-----------|
| Desarrollo principal | glm-5 (Z.ai) | glm-4.7 | abab6.5 |
| Revisión código | glm-4.7 | codestral | - |
| Consultas rápidas | glm-4.6 | - | - |
| Arquitectura | glm-5 | gpt-4o | - |
| Usuario final | gpt-4o | glm-4.7 | - |
| Fallback | abab6.5 | mistral-large | - |

---

## Gestión de Créditos

```javascript
// src/utils/credit-monitor.js

const PLAN_LIMITS = {
  zai: { monthly: 'unlimited', daily: null },
  minimax: { monthly: '20_eur', daily: null },
  mistral: { monthly: 'premium', daily: null },
  openai: { monthly: '9_eur', daily: 40 }, // ~40 mensajes GPT-4/día
};

export function trackUsage(provider, tokens) {
  // Implementar tracking
  console.log(`${provider}: ${tokens} tokens used`);
}

export function checkLimits(provider) {
  // Verificar límites antes de usar
  return true;
}
```

---

**Documento:** Configuración APIs Cloud
**Ubicación:** `docs/INSTALACION-PERSONAL/04-config-apis-cloud.md`
