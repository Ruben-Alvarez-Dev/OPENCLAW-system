# Análisis de Stack Personal - OPENCLAW-system

**ID:** DOC-PER-ANA-001
**Versión:** 1.0
**Fecha:** 2026-03-10
**Propietario:** Ruben

---

## Hardware Disponible

### Computación Principal

| Dispositivo | Specs | Rol Potencial | Tailscale IP |
|-------------|-------|---------------|--------------|
| **Mac Mini M1** | 16GB RAM, 256GB SSD + NVMe 4TB TB4 | Servidor principal / Nodo compute | `100.x.x.x` |
| **MacBook Pro M1 Max** | 32GB RAM, 1TB SSD | LLM Server (LMStudio Link) / Cliente pesado | `100.x.x.x` |
| **VPS Hetzner** | 8 vCPU, 24GB RAM | Cloud gateway / Nodo distribuido | IP pública |

### Dispositivos Móviles (Clientes)

| Dispositivo | Specs | Capacidad | Tailscale IP |
|-------------|-------|-----------|--------------|
| Samsung S9 FE+ | - | Cliente ligero | `100.x.x.x` |
| Xiaomi Pad 5 | - | Cliente ligero | `100.x.x.x` |
| Pixel Pro XL 10 | - | Cliente ligero | `100.x.x.x` |
| Xiaomi Note 12 5G | - | Cliente ligero | `100.x.x.x` |

### Red

```
Internet
    │
    ▼
Router ──── Ethernet ──── Mac Mini M1 (servidor principal)
    │
    └── WiFi ──── Resto dispositivos

Tailscale VPN (mesh)
    │
    ├── Mac Mini M1
    ├── MacBook Pro M1 Max
    ├── VPS Hetzner (bloqueado hacia resto)
    └── Dispositivos móviles
```

---

## Capacidades de Computación

### Mac Mini M1 (Servidor Principal)

| Recurso | Capacidad | Disponible para OPENCLAW |
|---------|-----------|--------------------------|
| CPU | M1 8-core | 6 cores dedicados |
| RAM | 16GB | 10-12GB (tras SO + apps) |
| SSD | 256GB | Sistema + apps críticas |
| NVMe | 4TB TB4 | Almacenamiento principal OPENCLAW |
| GPU | M1 8-core | Metal para Ollama |
| Red | 1Gbps + WiFi 6 | Gateway local |

**Roles ideales:**
- Gateway WebSocket (puerto 18789)
- Mission Control Dashboard (puerto 18790)
- Redis + almacenamiento vectorial
- Coordinador de agentes
- Ollama con modelos pequeños (3B-7B)

### MacBook Pro M1 Max (LLM Server Opcional)

| Recurso | Capacidad | Disponible para OPENCLAW |
|---------|-----------|--------------------------|
| CPU | M1 Max 10-core | 8 cores dedicados |
| RAM | 32GB | 16-22GB (50-70% libre según uso) |
| GPU | M1 Max 32-core | Potencia masiva para LLMs |
| SSD | 1TB | Modelos + cache |

**Roles ideales (cuando encendido):**
- LMStudio Link server (modelos grandes)
- Ollama con modelos 13B-70B (cuantizados)
- Inference server distribuido

### VPS Hetzner (Cloud Gateway)

| Recurso | Capacidad | Disponible para OPENCLAW |
|---------|-----------|--------------------------|
| CPU | 8 vCPU | 6-8 vCPU |
| RAM | 24GB | 18-20GB |
| Disco | ~100GB SSD | Sistema + datos |
| Red | 1Gbps ilimitado | Gateway público |

**Roles ideales:**
- Gateway público (acceso externo)
- Proxy inverso hacia Mac Mini
- Backup location
- Agentes cloud-only
- API externa

---

## Suscripciones AI Disponibles

### Locales (On-Premise)

| Herramienta | Capacidad | Uso Óptimo |
|-------------|-----------|------------|
| **Ollama** | M1 GPU | Modelos 3B-7B 24/7 |
| **LMStudio Link** | M1 Max (MBP) | Modelos 13B-70B bajo demanda |
| **llama.cpp** | CPU/GPU | Inferencia optimizada |

### Cloud (APIs)

| Proveedor | Plan | Crédito/Mes | Uso Óptimo |
|-----------|------|-------------|------------|
| **Z.ai** | Coding Plan Máximo | Alto | Desarrollo principal |
| **Minimax** | Coding Plan 20€ | Medio | Alternativa/backup |
| **Mistral** | Premium | Medio | Especializado |
| **ChatGPT** | Plus 9€ | Limitado | Consultas puntuales |

---

## Estrategia de Modelos por Hardware

### Mac Mini M1 (24/7)

```
Modelos siempre disponibles (Ollama):
├── llama3.2:3b        → Tareas rápidas, routing
├── qwen2.5:7b         → Código, lógica
└── nomic-embed-text   → Embeddings
```

### MacBook Pro M1 Max (Bajo Demanda)

```
Modelos cuando encendido (LMStudio Link):
├── llama3.1:70b-q4    → Razonamiento complejo
├── mixtral:8x7b-q4    → Multi-tarea
├── codestral:22b      → Código avanzado
└── qwen2.5:72b-q4     → General purpose
```

### Cloud APIs (Fallback/Especializado)

```
├── Z.ai glm-5/4.7     → Desarrollo principal
├── Minimax            → Backup
├── Mistral            → Tareas específicas
└── ChatGPT            → Consultas usuario
```

---

## Restricciones de Seguridad

### Tailscale Config Actual

```
VPS Hetzner:
├── Puede acceder a: Internet
└── BLOQUEADO hacia: Mac Mini, MBP, móviles

Mac Mini / MBP / Móviles:
├── Pueden comunicarse entre sí
└── Pueden acceder a VPS (si necesario)
```

### Puertos a Exponer

| Puerto | Servicio | Ubicación | Exposición |
|--------|----------|-----------|------------|
| 18789 | Gateway WS | Mac Mini/VPS | Localhost + Tailscale |
| 18790 | Mission Control | Mac Mini | Localhost + Tailscale |
| 11434 | Ollama | Mac Mini | Localhost |
| 1234 | LMStudio Link | MBP | Tailscale only |
| 6379 | Redis | Mac Mini | Localhost |

---

## Matriz de Decisión

| Escenario | Recomendación | Razón |
|-----------|---------------|-------|
| Desarrollo diario | M1 Mini standalone | Suficiente, 24/7 |
| Producción seria | Distribuido M1+VPS | Alta disponibilidad |
| Solo cloud | VPS standalone | Sin hardware local |
| Máximo rendimiento | M1+VPS+MBP | Toda la potencia |

---

## Próximos Pasos

1. [Ruta M1 Mini Standalone](./01-ruta-m1-mini.md)
2. [Ruta VPS Standalone](./02-ruta-vps-hetzner.md)
3. [Ruta Sistema Distribuido](./03-ruta-distribuida.md)

---

**Documento:** Análisis de Stack Personal
**Ubicación:** `docs/INSTALACION-PERSONAL/01-analisis-stack.md`
