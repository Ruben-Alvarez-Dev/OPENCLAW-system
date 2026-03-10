# Proveedores de IA SOTA

**ID:** DOC-REF-IA-001
**Versión:** 1.1
**Última actualización:** 2026-03-10
**Estado:** Referencia Oficial

---

## Descripción General

Este documento presenta una recopilación exhaustiva de proveedores de IA SOTA (State-of-the-Art) para integración con OPENCLAW-system: LLMs, Embeddings y STT.

### Criterios de Selección

| Criterio | Descripción |
|----------|-------------|
| Calidad de salida | Precisión y coherencia |
| Context window | Tamaño máximo de contexto |
| Latencia | Tiempo de respuesta |
| Costo | Precio por token |
| Disponibilidad | Uptime y SLA |

---

## Tabla Comparativa de LLMs

### Tier 1 - Premium

| Proveedor | Modelos | Context | Razonamiento | Coding | Costo/1M | SLA |
|-----------|---------|---------|--------------|--------|----------|-----|
| **OpenAI** | GPT-4o, o1, o3 | 128K-200K | ★★★★★ | ★★★★★ | $2.50-$60 | 99.9% |
| **Anthropic** | Claude 3.5 Sonnet, Haiku, Opus | 200K | ★★★★★ | ★★★★★ | $0.25-$15 | 99.9% |
| **Google** | Gemini 2.0 Flash, 1.5 Pro | 1M-2M | ★★★★★ | ★★★★ | $0.075-$7 | 99.95% |
| **xAI** | Grok-2, Grok-2-mini | 128K | ★★★★ | ★★★★ | $2-$10 | 99.5% |

### Tier 2 - Competitivos

| Proveedor | Modelos | Context | Razonamiento | Coding | Costo/1M | SLA |
|-----------|---------|---------|--------------|--------|----------|-----|
| **Mistral** | Mistral Large, Codestral | 32K-128K | ★★★★ | ★★★★★ | $0.20-$8 | 99.5% |
| **Cohere** | Command R+, Aya | 128K-256K | ★★★★ | ★★★ | $0.50-$5 | 99.9% |
| **Meta Llama** | Llama 3.3 70B, 3.2 90B | 128K | ★★★★ | ★★★★ | Variable | - |
| **DeepSeek** | DeepSeek-V3, Coder | 64K-128K | ★★★★ | ★★★★★ | $0.14-$0.28 | 99% |
| **AI21** | Jamba-1.5, Jurassic-2 | 256K | ★★★★ | ★★★ | $0.50-$12 | 99.5% |

### Tier 3 - Regionales

| Proveedor | Modelos | Context | Especialidad | Región |
|-----------|---------|---------|--------------|--------|
| **Zhipu (GLM)** | GLM-4, GLM-4-Plus | 128K-1M | Razonamiento | China |
| **Qwen (Alibaba)** | Qwen-2.5, Qwen-Max | 32K-128K | Multi-idioma | China |
| **Moonshot** | Kimi | 200K | Contexto largo | China |
| **Naver** | HyperCLOVA X | 8K-32K | Coreano | Corea |

### Tier 4 - Open Source (Self-Hosted)

| Proveedor | Modelos | Context | Hardware | Uso |
|-----------|---------|---------|----------|-----|
| **Ollama** | Llama 3.2, Mistral, Gemma 2 | 4K-128K | 8GB+ RAM | Local |
| **vLLM** | Llama 3.1, Mixtral | 32K-128K | 16GB+ VRAM | Producción |
| **LocalAI** | Múltiples GGUF | Variable | 8GB+ RAM | Edge |

### Tier 5 - Nicho

| Proveedor | Modelos | Especialidad |
|-----------|---------|--------------|
| **Perplexity** | Sonar, Sonar-Pro | Búsqueda web |
| **Together AI** | Llama 3.3, Mistral | Inferencia rápida |
| **Groq** | Llama 3.3, Mixtral | Ultra-low latency |
| **Fireworks** | Llama 3.2, Qwen2 | Low latency |

---

## Modelos Recomendados por Tarea

### Razonamiento

| Tarea | Primario | Fallback | Justificación |
|-------|----------|----------|---------------|
| Análisis arquitectónico | Claude 3.5 Sonnet | GPT-4o | Razonamiento estructurado |
| Toma de decisiones | o1/o3 | Claude 3 Opus | Chain-of-thought nativo |
| Planificación | Claude 3.5 Sonnet | Gemini 1.5 Pro | Balance calidad/costo |

### Coding

| Tarea | Primario | Fallback | Justificación |
|-------|----------|----------|---------------|
| Production-ready | Claude 3.5 Sonnet | GPT-4o | Mejor calidad |
| Refactoring | Codestral | Claude 3.5 Sonnet | Especializado |
| Debugging | Claude 3.5 Sonnet | GPT-4-turbo | Análisis de errores |
| Tests | Claude 3.5 Haiku | Codestral | Rápido/económico |

### Chat

| Tarea | Primario | Fallback | Justificación |
|-------|----------|----------|---------------|
| General | Claude 3.5 Haiku | GPT-4o-mini | Rápido y natural |
| Técnico | Claude 3.5 Sonnet | GPT-4o | Profundo |
| Respuestas rápidas | Groq Llama 3.3 | Haiku | Ultra-low latency |

---

## Proveedores de Embeddings

| Proveedor | Modelo | Dim | Max Doc | Costo/1M | Calidad |
|-----------|--------|-----|---------|----------|---------|
| **OpenAI** | text-embedding-3-large | 3072 | 8191 | $0.13 | ★★★★★ |
| **OpenAI** | text-embedding-3-small | 1536 | 8191 | $0.02 | ★★★★ |
| **Cohere** | embed-v3 | 1024 | 512 | $0.10 | ★★★★★ |
| **Voyage** | voyage-3 | 1024 | 32000 | $0.12 | ★★★★★ |
| **Voyage** | voyage-code-3 | 1024 | 16000 | $0.12 | ★★★★★ |
| **Google** | text-embedding-004 | 768 | 2048 | $0.03 | ★★★★ |
| **Ollama** | nomic-embed-text | 768 | 8192 | Gratis* | ★★★ |

### Recomendaciones

| Uso | Recomendado | Alternativa |
|-----|-------------|-------------|
| RAG production | Voyage-3 | Cohere embed-v3 |
| Código | voyage-code-3 | OpenAI large |
| Económico | OpenAI small | Jina v3 |
| Local | Ollama nomic | mxbai-embed-large |

---

## Proveedores de STT

| Proveedor | Modelo | Idiomas | WER | Latencia | Costo/min |
|-----------|--------|---------|-----|----------|-----------|
| **OpenAI** | Whisper-1 | 99+ | 4.2% | ~5s | $0.006 |
| **Google** | Chirp 2 | 125+ | 3.5% | ~2s | $0.006 |
| **Deepgram** | Nova-2 | 36+ | 4.8% | <1s | $0.0043 |
| **Groq** | Whisper-large-v3 | 99+ | 4.2% | <1s | $0.0036 |
| **AssemblyAI** | Universal-2 | 99+ | 5.1% | ~3s | $0.006 |
| **Azure** | Speech SDK | 100+ | 3.9% | ~2s | $0.01 |

### Recomendaciones

| Escenario | Proveedor | Justificación |
|-----------|-----------|---------------|
| Tiempo real | Groq Whisper | Ultra-low latency |
| Alta precisión | Google Chirp 2 | Mejor WER |
| Económico | Groq Whisper | Mejor precio |
| Multi-idioma | OpenAI Whisper | Amplio soporte |

---

## Estrategia de Fallback

```yaml
fallback_chain:
  reasoning:
    primary: claude-3-5-sonnet-20241022
    secondary: gpt-4o-2024-11-20
    tertiary: gemini-1.5-pro
    
  coding:
    primary: claude-3-5-sonnet-20241022
    secondary: codestral-latest
    tertiary: gpt-4o
    
  fast:
    primary: claude-3-5-haiku-20241017
    secondary: groq/llama-3.3-70b
    tertiary: gpt-4o-mini
```

---

## Referencias Oficiales

| Proveedor | Documentación |
|-----------|---------------|
| OpenAI | https://platform.openai.com/docs |
| Anthropic | https://docs.anthropic.com |
| Google | https://ai.google.dev/docs |
| Mistral | https://docs.mistral.ai |
| Cohere | https://docs.cohere.com |
| xAI | https://docs.x.ai |
| DeepSeek | https://platform.deepseek.com |
| Groq | https://console.groq.com/docs |

---

> **Ver también:** [00-openclaw-docs.md](00-openclaw-docs.md) | [02-architectures.md](02-architectures.md)
