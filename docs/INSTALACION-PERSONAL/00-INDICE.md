# Índice - Instalación Personal OPENCLAW

**Propietario:** Ruben
**Fecha:** 2026-03-10
**Versión:** 3.1
**Estado:** ✅ PRODUCTION READY

---

## ⚠️ ANTES DE EMPEZAR

**LEE OBLIGATORIAMENTE:** [06-auditoria-correcciones.md](./06-auditoria-correcciones.md)

Este documento contiene correcciones de seguridad CRÍTICAS que debes aplicar a las rutas de instalación.

---

## ✅ Correcciones Aplicadas (2026-03-10)

| Problema | Estado | Solución |
|----------|--------|----------|
| Puerto Gateway expuesto | ✅ RESUELTO | UFW restrictivo localhost/Tailscale |
| API Keys opcionales | ✅ RESUELTO | Ahora obligatorias en pre-flight |
| Terminología inconsistente | ✅ RESUELTO | Director/Ejecutor/Archivador unificado |
| Sin .env.example | ✅ RESUELTO | Creado con variables tri-agente |
| Sin docker-compose | ✅ RESUELTO | Arquitectura 3 agentes + Gateway + Redis |
| Roles Ansible incompletos | ✅ RESUELTO | openclaw-gateway, openclaw-agents, openclaw-ollama |
| Sin RTO/RPO en backups | ✅ RESUELTO | RTO 4h, RPO 24h definidos |

---

## Estructura de Documentos

```
docs/INSTALACION-PERSONAL/
│
├── 00-INDICE.md                    ← ESTE ARCHIVO
├── 01-analisis-stack.md            ← Tu hardware y capacidades
│
├── RUTAS DE INSTALACIÓN
│   ├── 02-ruta-m1-mini.md          ← Ruta 1: Mac Mini standalone
│   ├── 03-ruta-vps-hetzner.md      ← Ruta 2: VPS standalone
│   └── 04-ruta-distribuida.md      ← Ruta 3: Sistema distribuido
│
├── ARQUITECTURA TRI-AGENTE (CORE)
│   ├── 09-TRI-AGENTE-OPENCLAW.md   ← Implementación técnica del concilio
│   └── 10-PATRON-TRI-AGENTE.md     ← TEORÍA: Patrón arquitectónico
│
├── EXTENSIÓN ENTERPRISE
│   └── 11-ARQUITECTURA-HOLISTICA.md ← Arquitectura completa 7 capas
│
├── CONFIGURACIÓN
│   └── 05-config-apis-cloud.md     ← APIs cloud (Z.ai, Minimax, etc.)
│
├── AUDITORÍA Y CALIDAD
│   ├── 06-auditoria-correcciones.md ← ⚠️ CORRECCIONES CRÍTICAS
│   └── 12-AUDITORIA-COHERENCIA.md   ← Estado de coherencia
│
└── USO
    └── 07-capacidades-experiencia.md ← Qué hace el sistema y cómo usarlo
```

---

## Arquitectura del Sistema

El sistema se basa en **3 procesos Node.js** que forman un **Concilio Tri-Agente**:

```
┌─────────────────────────────────────────────────────────────────┐
│                      GATEWAY FASTIFY                             │
│                      Puerto: 18789                               │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │  DIRECTOR   │  │  EJECUTOR   │  │ ARCHIVADOR  │             │
│  │ Puerto:8081 │◄─┤ Puerto:8082 │◄─┤ Puerto:8083 │             │
│  │             │  │             │  │             │             │
│  │ Opus 4.6    │  │ Sonnet 4.6  │  │ Haiku 4.5   │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│        │                │                 ▲                      │
│        └────────────────┴─────────────────┘                      │
│              Redis Pub/Sub (comunicación)                        │
└─────────────────────────────────────────────────────────────────┘
```

**Stack Tecnológico:**
- **Gateway**: Fastify + WebSocket
- **Agentes**: Node.js + LLM SDK
- **Comunicación**: Redis Pub/Sub
- **Memoria**: LanceDB (vectorial)

---

## Rutas de Instalación

### Ruta 1: M1 Mac Mini Standalone (RECOMENDADO)

**Archivo:** [02-ruta-m1-mini.md](./02-ruta-m1-mini.md)

| Aspecto | Detalle |
|---------|---------|
| **Tiempo** | 3-4 horas |
| **Dificultad** | Media |
| **Modelos** | Locales (Ollama + Metal) |
| **Acceso** | Local + Tailscale |

**Cuándo usar:**
- Primera instalación
- Desarrollo local
- Uso personal/familiar
- Sin necesidad de acceso público

---

### Ruta 2: VPS Hetzner Standalone

**Archivo:** [03-ruta-vps-hetzner.md](./03-ruta-vps-hetzner.md)

| Aspecto | Detalle |
|---------|---------|
| **Tiempo** | 2-3 horas |
| **Dificultad** | Media-Alta |
| **Modelos** | Cloud APIs (Z.ai, Minimax) |
| **Acceso** | Público (IP dedicada) |

**Cuándo usar:**
- Acceso público necesario
- Sin hardware Apple
- APIs cloud como LLM principal

---

### Ruta 3: Sistema Distribuido (MÁXIMO RENDIMIENTO)

**Archivo:** [04-ruta-distribuida.md](./04-ruta-distribuida.md)

| Aspecto | Detalle |
|---------|---------|
| **Tiempo** | 5-6 horas |
| **Dificultad** | Alta |
| **Modelos** | Híbrido (local + cloud) |
| **Acceso** | Local + Tailscale + Público |

**Arquitectura:**
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Mac Mini   │────►│  MacBook    │     │     VPS     │
│   (Core)    │     │ (LLM Server)│     │  (Gateway)  │
│   24/7      │     │  On-demand  │     │   24/7      │
└─────────────┘     └─────────────┘     └─────────────┘
      │                                         │
      │ Tailscale                               │ Público
      ▼                                         ▼
┌─────────────┐                         ┌─────────────┐
│   Móviles   │                         │  Internet   │
│  (Clientes) │                         │  (Usuarios) │
└─────────────┘                         └─────────────┘
```

---

## Flujo de Instalación

```
    ┌─────────────────────────────────────┐
    │  1. LEER: 01-analisis-stack.md      │
    │     (verificar tu hardware)         │
    └─────────────────┬───────────────────┘
                      ▼
    ┌─────────────────────────────────────┐
    │  2. LEER: 06-auditoria-correcciones │
    │     (seguridad CRÍTICA)             │
    └─────────────────┬───────────────────┘
                      ▼
    ┌─────────────────────────────────────┐
    │  3. ELEGIR: Ruta 1, 2, o 3          │
    │     (02, 03, o 04)                  │
    └─────────────────┬───────────────────┘
                      ▼
    ┌─────────────────────────────────────┐
    │  4. SEGUIR: Fases en orden exacto   │
    └─────────────────┬───────────────────┘
                      ▼
    ┌─────────────────────────────────────┐
    │  5. CONFIGURAR: 09-TRI-AGENTE       │
    │     (concilio Director/Ejec/Arch)   │
    └─────────────────┬───────────────────┘
                      ▼
    ┌─────────────────────────────────────┐
    │  6. VERIFICAR: Smoke tests          │
    └─────────────────┬───────────────────┘
                      ▼
    ┌─────────────────────────────────────┐
    │  7. LEER: 07-capacidades-experiencia│
    │     (cómo usar el sistema)          │
    └─────────────────────────────────────┘
```

---

## Checklist de Decisión Rápida

```
¿Es tu PRIMERA instalación?
│
├─ SÍ ──────────────────────────────────► RUTA 1: M1 Mac Mini
│
└─ NO
   │
   └─ ¿Necesitas acceso PÚBLICO desde internet?
      │
      ├─ SÍ ─────────────────────────────► RUTA 3: Distribuida
      │                                   (o Ruta 2 si no tienes Mac)
      │
      └─ NO ─────────────────────────────► RUTA 1: M1 Mac Mini
```

---

## Resumen de Capacidades

Una vez instalado, el sistema puede:

| Capacidad | Descripción |
|-----------|-------------|
| **Chat inteligente** | Procesa lenguaje natural |
| **9 dominios** | /dev, /infra, /crypto, /inversiones, /hosteleria, /academico, /fitness, /english, /general |
| **Validación tri-agente** | Director → Ejecutor → Archivador |
| **Memoria 4 niveles** | Recuerda contexto entre sesiones |
| **Acceso remoto** | Vía Tailscale desde cualquier dispositivo |
| **Modelos locales** | Sin internet para tareas básicas |
| **Fallback cloud** | Z.ai, Minimax, Mistral si necesitas más |
| **Dashboard** | Mission Control para monitoreo |

**Ver detalles completos:** [07-capacidades-experiencia.md](./07-capacidades-experiencia.md)

---

## Documentación Core del Concilio

### 09-TRI-AGENTE-OPENCLAW.md
**Implementación técnica del Concilio Tri-Agente**

- Arquitectura de 3 procesos Node.js
- Configuración Redis Pub/Sub
- Código de los agentes (Director, Ejecutor, Archivador)
- Scripts de control
- PM2 para daemonización

### 10-PATRON-TRI-AGENTE.md
**Teoría del patrón arquitectónico**

- Arquitectura fractal recursiva
- Flujos de decisión
- Memoria del concilio
- Communication Ring
- RAG Jerárquico
- Learning Engine

### 11-ARQUITECTURA-HOLISTICA.md
**Extensión Enterprise (7 capas)**

- Arquitectura completa multi-nivel
- Observability (Prometheus, Grafana)
- Secrets Management (Vault)
- Message Broker (Redis Streams)
- Base de datos principal (PostgreSQL)

---

## Soporte

| Problema | Consultar |
|----------|-----------|
| Dudas sobre hardware | [01-analisis-stack.md](./01-analisis-stack.md) |
| Problemas de seguridad | [06-auditoria-correcciones.md](./06-auditoria-correcciones.md) |
| Como usar el sistema | [07-capacidades-experiencia.md](./07-capacidades-experiencia.md) |
| Configurar APIs | [05-config-apis-cloud.md](./05-config-apis-cloud.md) |
| Implementar tri-agente | [09-TRI-AGENTE-OPENCLAW.md](./09-TRI-AGENTE-OPENCLAW.md) |
| Teoria del patron | [10-PATRON-TRI-AGENTE.md](./10-PATRON-TRI-AGENTE.md) |
| Documentacion general | `docs/00-INDICE.md` |

---

## Checklist de Placeholders (PRE-INSTALACION)

Antes de ejecutar cualquier comando de instalacion, verifica que has reemplazado estos placeholders:

### Variables de Entorno

| Placeholder | Debes reemplazar por | Ubicacion tipica |
|-------------|---------------------|------------------|
| `$OPENCLAW_ROOT` | Ruta real de instalacion | `/Volumes/NVMe-4TB/openclaw` o `/opt/openclaw` |
| `TU_VPS_IP` | IP publica de tu VPS | Ejemplo: `123.45.67.89` |
| `100.x.x.x` | IP Tailscale del dispositivo | Obten con `tailscale ip` |
| `MACMINI_IP` | IP del Mac Mini en red local | Ejemplo: `192.168.1.100` |

### APIs y Claves

| Placeholder | Debes reemplazar por | Donde conseguir |
|-------------|---------------------|-----------------|
| `sk-ant-...` | API key de Anthropic | console.anthropic.com |
| `TU_ZAI_API_KEY` | API key de Z.ai | z.ai dashboard |
| `TU_MINIMAX_KEY` | API key de Minimax | minimaxi.com |
| `sk-...` | API key de OpenAI | platform.openai.com |

### Scripts (Editar antes de ejecutar)

| Script | Variables a configurar |
|--------|----------------------|
| `scripts/backup.sh` | `BACKUP_DIR`, `REDIS_DUMP_PATH`, `OPENCLAW_ROOT` |
| `scripts/backup-remote.sh` | `REMOTE_HOST`, `REMOTE_USER` |
| `scripts/sync-knowledge.sh` | `REMOTE_HOST`, `REMOTE_USER` |

### Verificacion Rapida

```bash
# Buscar placeholders sin reemplazar en scripts
grep -rn "TU_VPS_IP\|100\.x\.x\.x\|MACMINI_IP" scripts/

# Si encuentra resultados, EDITA esos archivos antes de continuar
```

---

**Ubicacion:** `docs/INSTALACION-PERSONAL/00-INDICE.md`
**Version:** 3.2
**Fecha:** 2026-03-10
