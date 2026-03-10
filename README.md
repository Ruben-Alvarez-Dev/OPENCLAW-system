# OPENCLAW - Sistema Multi-Agente Jerárquico

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-3.0.0-green.svg)](https://github.com/Ruben-Alvarez-Dev/OPENCLAW-system)
[![Status](https://img.shields.io/badge/status-production%20ready-brightgreen.svg)](https://github.com/Ruben-Alvarez-Dev/OPENCLAW-system)
[![Architecture](https://img.shields.io/badge/architecture-tri--agent-orange.svg)](https://github.com/Ruben-Alvarez-Dev/OPENCLAW-system)

**Framework Base:** OpenClaw v2026.3.8 | **20+ Canales** | **30+ Proveedores IA**

---

## Resumen

OPENCLAW es un sistema multi-agente jerárquico diseñado para emular organizaciones humanas estructuradas. Combina orquestación, especialización por dominio y unidades tri-agente para producir salidas estables y verificables.

### Características Principales

| Característica | Descripción |
|----------------|-------------|
| 🏗️ **Arquitectura Jerárquica** | 4 niveles: SIS → JEF → ESP → SUB |
| 🔄 **Patrón Tri-Agente** | Director + Ejecutor + Archivador |
| 🎯 **Routing por Dominio** | Namespaces automáticos `/dev`, `/infra`, etc. |
| 🧠 **Motor de Conocimiento** | 5 capas de fuentes verificadas |
| 💾 **Memoria Persistente** | 4 niveles: Agente, Unidad, Dominio, Global |
| 🔒 **Seguridad Endurecida** | Sandbox Docker, exec-approvals, firewall |

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│  NIVEL SIS — ORQUESTADOR (tri-agente)                           │
│  Director + Ejecutor + Archivador                               │
│  → Punto de entrada, coordinación, routing                      │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│  NIVEL JEF — 6 CATEDRÁTICOS                                     │
│  CON | ING | OPE | RHU | REX | COM                               │
│  → Decisiones estratégicas, coordinación de dominio             │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│  NIVEL ESP — 9 ESPECIALISTAS                                    │
│  DEV | INF | HOS | ACA | GEN | CRI | FIN | DEP | IDI            │
│  → Ejecución con validación interna (tri-agente)                │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│  NIVEL SUB — SUBAGENTES EFÍMEROS                                │
│  → Trabajadores temporales, sin memoria                         │
└─────────────────────────────────────────────────────────────────┘
```

### Tri-Agente (Concilio)

| Rol | Función | Puerto |
|-----|---------|--------|
| **Director** | Planificación, estrategia, delegación | 8081 |
| **Ejecutor** | Ejecución, cálculos, generación | 8082 |
| **Archivador** | Validación, memoria, persistencia | 8083 |
| **Gateway** | API unificada, autenticación | 18789 |

---

## Inicio Rápido

### Opciones de Instalación

| Ruta | Descripción | Documentación |
|------|-------------|---------------|
| 🍎 **M1 Mini** | Local con Ollama | [Guía](docs/INSTALACION-PERSONAL/02-ruta-m1-mini.md) |
| 🌐 **VPS Hetzner** | Cloud económico | [Guía](docs/INSTALACION-PERSONAL/03-ruta-vps-hetzner.md) |
| 🌍 **Distribuido** | M1 + VPS con Tailscale | [Guía](docs/INSTALACION-PERSONAL/04-ruta-distribuida.md) |

### Requisitos Mínimos

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| CPU | 4 cores | 8 cores |
| RAM | 8 GB | 16 GB |
| Disco | 50 GB SSD | 100 GB SSD |
| Node.js | v20+ | v23.11.1 |
| pnpm | v9+ | v10.23.0 |

### Comandos de Inicio

```bash
# Clonar repositorio
git clone https://github.com/Ruben-Alvarez-Dev/OPENCLAW-system.git
cd OPENCLAW-system

# Instalar dependencias
pnpm install

# Configurar entorno
cp .env.example .env
# Editar .env con tus API keys

# Iniciar servicios
pnpm build && pm2 start ecosystem.config.js
```

---

## Estructura del Proyecto

```
OPENCLAW-system/
├── docs/                    # Documentación completa
│   ├── 01-SISTEMA/          # Arquitectura y stack
│   ├── 12-IMPLEMENTACION/   # Guías de instalación
│   ├── 13-OPERACIONES/      # Gestión de servicios
│   └── INSTALACION-PERSONAL/# Rutas específicas
│
├── biblioteca/              # Recursos del sistema
│   ├── protocolos/          # PRO-001 a PRO-010
│   ├── plantillas/          # PLA-001, PLA-002
│   └── registros/           # REG-001 a REG-003
│
├── sistema/                 # Configuración SIS
├── jefaturas/               # 6 Catedráticos
├── especialistas/           # 9 Unidades ESP
├── scripts/                 # Utilidades
└── config/                  # Configuración adicional
```

---

## Namespaces de Usuario

| Namespace | Dominio | Especialista |
|-----------|---------|--------------|
| `/dev` | Desarrollo | ESP-DES-001 |
| `/infra` | Infraestructura | ESP-INF-001 |
| `/hosteleria` | Hostelería | ESP-HOS-001 |
| `/academico` | Académico | ESP-ACA-001 |
| `/general` | General | ESP-GEN-001 |
| `/crypto` | Criptomonedas | ESP-CRI-001 |
| `/inversiones` | Finanzas | ESP-FIN-001 |
| `/fitness` | Deportes | ESP-DEP-001 |
| `/english` | Idiomas | ESP-IDI-001 |

---

## Documentación

| Documento | Descripción |
|-----------|-------------|
| [📋 Índice Principal](INDEX.md) | Mapa completo del sistema |
| [🤖 Guía Claude](CLAUDE.md) | Instrucciones para Claude Code |
| [📖 Índice Docs](docs/00-INDICE.md) | Documentación técnica |
| [🔄 CHANGELOG](CHANGELOG.md) | Historial de cambios |
| [🔒 Seguridad](SECURITY.md) | Políticas de seguridad |

---

## Comandos Principales

### Gestión de Servicios

```bash
# Estado de todos los servicios
pm2 status

# Logs en tiempo real
pm2 logs

# Reiniciar servicio específico
pm2 restart sis-director | sis-ejecutor | sis-archivador

# Health check
curl http://127.0.0.1:18789/health
```

### Control de Herramientas

```bash
./scripts/tools-control.sh gpt-researcher start|stop|status
./scripts/tools-control.sh engram stats|search|save
./scripts/tools-control.sh status  # Verificar todas
```

---

## Seguridad

El sistema implementa múltiples capas de seguridad:

| Capa | Controles |
|------|-----------|
| **Perímetro** | Token auth, allowFrom lists, rate limiting |
| **Aplicación** | Validación Zod, auditoría tools, sanitización |
| **Ejecución** | Docker sandbox, exec-approvals, detección ofuscación |
| **Aislamiento** | Workspace mounts, safe-bin policy, readonly FS |

Ver [SECURITY.md](SECURITY.md) para detalles completos.

---

## Puertos del Sistema

| Servicio | Puerto | Bind | Protocolo |
|----------|--------|------|-----------|
| Gateway | 18789 | 127.0.0.1 | HTTP/WS |
| Director | 8081 | 127.0.0.1 | HTTP |
| Ejecutor | 8082 | 127.0.0.1 | HTTP |
| Archivador | 8083 | 127.0.0.1 | HTTP |
| Redis | 6379 | 127.0.0.1 | TCP |
| Ollama | 11434 | 127.0.0.1 | HTTP |

---

## Contribuir

Ver [CONTRIBUTING.md](CONTRIBUTING.md) para guidelines de contribución.

---

## Licencia

Este proyecto está bajo la Licencia MIT - ver [LICENSE](LICENSE) para detalles.

---

## Autor

**Ruben Alvarez**
- GitHub: [@Ruben-Alvarez-Dev](https://github.com/Ruben-Alvarez-Dev)

---

**Repositorio:** https://github.com/Ruben-Alvarez-Dev/OPENCLAW-system
