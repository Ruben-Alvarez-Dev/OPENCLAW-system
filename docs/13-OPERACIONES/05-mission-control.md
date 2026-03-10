# Mission Control - Dashboard de Operaciones

**ID:** DOC-OPE-MCN-001
**Versión:** 1.0
**Fecha:** 2026-03-10
**Prioridad:** ALTA
**Estado:** Plan de Implementación

---

## 1. Resumen Ejecutivo

Mission Control es un dashboard web que proporciona visibilidad y control sobre OPENCLAW-system en tiempo real. Permite operar el sistema 24/7 desde cualquier ubicación sin necesidad de acceso SSH directo.

---

## 2. Arquitectura del Dashboard

### 2.1 Visión General

```
┌─────────────────────────────────────────────────────────────────┐
│                    MISSION CONTROL                               │
│                    Puerto: 18790                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │ SISTEMA  │ │ AGENTES  │ │ TAREAS   │ │ MEMORIA  │           │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘           │
│                                                                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │ CLUSTERS │ │ LOGS     │ │ METRICAS │ │ CONFIG   │           │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘           │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    WEBSOCKET TIEMPO REAL                    │ │
│  │                    Puerto: 18789 (Gateway)                  │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Stack Tecnológico

| Componente | Tecnología | Razón |
|------------|------------|-------|
| **Framework** | Next.js 14+ | App Router, SSR, TypeScript nativo |
| **UI** | Tailwind CSS + shadcn/ui | Coherente con documento de diseño |
| **Estado** | Zustand | Ligero, sin boilerplate |
| **Tiempo real** | WebSocket (Gateway) | Ya existe en puerto 18789 |
| **Gráficos** | Recharts | Simple, reactivo |
| **Iconos** | Lucide React | Consistente |

### 2.3 Puertos del Sistema

```
┌─────────────────────────────────────────────────────────────────┐
│                    MAPEO DE PUERTOS                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  18789 → Gateway (WebSocket/API) - YA EXISTE                    │
│  18790 → Mission Control (Dashboard) - NUEVO                    │
│  11434 → Ollama (LLM local) - YA EXISTE                         │
│  6379  → Redis (Cache/Bus) - YA EXISTE                          │
│                                                                  │
│  ⚠️ IMPORTANTE: Solo localhost, nunca exponer a internet        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Pantallas del Dashboard

### 3.1 Pantalla Principal: Sistema

```
┌─────────────────────────────────────────────────────────────────┐
│  OPENCLAW-system v2.4.0                    🟢 Online | ⏱️ 14:32 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────┐  ┌─────────────────────┐              │
│  │     ORQUESTADOR     │  │     6 CATEDRÁTICOS  │              │
│  │                     │  │                     │              │
│  │  🟢 Director        │  │  🟢 CON (Conocim.)  │              │
│  │  🟢 Ejecutor        │  │  🟢 ING (Ingenier.) │              │
│  │  🟢 Archivador      │  │  🟢 OPE (Operacio.) │              │
│  │                     │  │  🟢 RHU (RRHH)      │              │
│  │  Uptime: 72h 34m    │  │  🟢 REX (Relacion.) │              │
│  │  Tareas: 1,234      │  │  🟢 COM (Comunicac.)│              │
│  └─────────────────────┘  └─────────────────────┘              │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    ACTIVIDAD RECIENTE                        ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │ 14:32:15 │ /dev │ ESP-DES-001 │ Tarea completada ✓          ││
│  │ 14:31:45 │ /infra │ ESP-INF-001 │ Validando cambios...      ││
│  │ 14:30:22 │ /dev │ ESP-DES-001 │ Nueva tarea iniciada        ││
│  │ 14:28:11 │ SIS │ Orquestador │ Routing completado           ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐│
│  │   CPU: 23% ████  │  │  RAM: 4.2GB ████ │  │ DISK: 45GB ██ ││
│  └──────────────────┘  └──────────────────┘  └────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Pantalla: Agentes

```
┌─────────────────────────────────────────────────────────────────┐
│  AGENTES                                  🔍 Buscar...  [+ Nuevo]│
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ NIVEL SIS - ORQUESTADOR                                     ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │  🟢 Director   │ Tareas: 45 │ Consenso: 98% │ Último: 2m   ││
│  │  🟢 Ejecutor   │ Tareas: 156│ Éxito: 95%   │ Último: 30s  ││
│  │  🟢 Archivador │ Valid.: 89 │ Aprobado: 92%│ Último: 1m   ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ NIVEL JEF - CATEDRÁTICOS                                    ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │  🟢 JEF-CON │ 12 unidades │ 45 tareas/día │ Activo         ││
│  │  🟢 JEF-ING │ 8 unidades  │ 78 tareas/día │ Activo         ││
│  │  🟢 JEF-OPE │ 6 unidades  │ 23 tareas/día │ Activo         ││
│  │  🟢 JEF-RHU │ 4 unidades  │ 12 tareas/día │ Activo         ││
│  │  🟢 JEF-REX │ 3 unidades  │ 8 tareas/día  │ Activo         ││
│  │  🟢 JEF-COM │ 2 unidades  │ 15 tareas/día │ Activo         ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ NIVEL ESP - ESPECIALISTAS ACTIVOS                           ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │  🟢 ESP-DES-001 │ /dev       │ ⚡ Procesando tarea         ││
│  │  🟢 ESP-INF-001 │ /infra     │ ✅ Idle                     ││
│  │  🟢 ESP-HOS-001 │ /hosteleria│ ✅ Idle                     ││
│  │  🟢 ESP-ACA-001 │ /academico │ ✅ Idle                     ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### 3.3 Pantalla: Tareas (Kanban)

```
┌─────────────────────────────────────────────────────────────────┐
│  TAREAS                                    [+ Nueva Tarea]       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────┐│
│  │   BACKLOG    │ │  EN PROGRESO │ │   REVISIÓN   │ │  HECHO   ││
│  │      (8)     │ │      (3)     │ │      (2)     │ │   (45)   ││
│  ├──────────────┤ ├──────────────┤ ├──────────────┤ ├──────────┤│
│  │              │ │              │ │              │ │          ││
│  │ ┌──────────┐ │ │ ┌──────────┐ │ │ ┌──────────┐ │ │ ✓ Task 1 ││
│  │ │ Task 101 │ │ │ │ Task 98  │ │ │ │ Task 95  │ │ │ ✓ Task 2 ││
│  │ │ /dev     │ │ │ │ /infra   │ │ │ │ /dev     │ │ │ ✓ Task 3 ││
│  │ │ Prior:Media│ │ │ │ ESP-INF  │ │ │ │ ESP-DES  │ │ │ ...      ││
│  │ └──────────┘ │ │ │ 45% ████ │ │ │ └──────────┘ │ │          ││
│  │              │ │ └──────────┘ │ │              │ │          ││
│  │ ┌──────────┐ │ │              │ │ ┌──────────┐ │ │          ││
│  │ │ Task 102 │ │ │ ┌──────────┐ │ │ │ Task 94  │ │ │          ││
│  │ │ /crypto  │ │ │ │ Task 97  │ │ │ │ /academ  │ │ │          ││
│  │ │ Prior:Alta│ │ │ │ /dev     │ │ │ └──────────┘ │ │          ││
│  │ └──────────┘ │ │ │ 78% █████│ │ │              │ │          ││
│  │              │ │ └──────────┘ │ │              │ │          ││
│  └──────────────┘ └──────────────┘ └──────────────┘ └──────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### 3.4 Pantalla: Memoria

```
┌─────────────────────────────────────────────────────────────────┐
│  MEMORIA                              🔍 Buscar en memoria...    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ ESTADÍSTICAS DE MEMORIA                                     ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │  📊 Agente:    1,234 entradas  │ 45MB                       ││
│  │  📊 Unidad:      567 entradas  │ 23MB                       ││
│  │  📊 Dominio:     234 entradas  │ 12MB                       ││
│  │  📊 Global:       45 entradas  │ 2MB                        ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ MEMORIA RECIENTE                                            ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │ 📝 14:30 │ ESP-DES-001 │ "Decisión: Usar REST sobre GraphQL"││
│  │ 📝 14:15 │ ESP-INF-001 │ "Config: Redis persistence AOF"    ││
│  │ 📝 13:45 │ JEF-ING     │ "ADR-045: Triunvirato mandatory"   ││
│  │ 📝 12:00 │ SIS         │ "Sistema actualizado a v2.4.0"     ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ ADRs (Architecture Decision Records)                        ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │ 📋 ADR-001: Arquitectura Tri-Agente                         ││
│  │ 📋 ADR-002: Validación Multicapa                            ││
│  │ 📋 ADR-003: Memoria Jerárquica 4 Niveles                    ││
│  │ [Ver todos...]                                              ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### 3.5 Pantalla: Logs

```
┌─────────────────────────────────────────────────────────────────┐
│  LOGS Y AUDITORÍA                      [Filtrar] [Exportar]     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Filtros: [Todos ▼] [Nivel ▼] [Agente ▼] [Dominio ▼] [Tiempo ▼] │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ 🟢 INFO  │ 14:32:15 │ ESP-DES-001 │ Tarea completada        ││
│  │ 🟡 WARN  │ 14:31:45 │ ESP-INF-001 │ Timeout retry 2/3       ││
│  │ 🟢 INFO  │ 14:31:30 │ Gateway    │ WS connection established││
│  │ 🔴 ERROR │ 14:30:15 │ ESP-INF-001 │ Validation failed       ││
│  │ 🟢 INFO  │ 14:30:00 │ SIS-Director│ Routing to /dev         ││
│  │ 🟢 INFO  │ 14:29:45 │ JEF-ING    │ Delegating to ESP-DES   ││
│  │ 🟡 WARN  │ 14:29:30 │ Ollama     │ High latency: 2.3s      ││
│  │ 🟢 INFO  │ 14:29:15 │ ESP-DES-001 │ Starting task #98       ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  [▶ Streaming ON] │ Mostrando últimos 1000 │ Auto-scroll ✓      │
└─────────────────────────────────────────────────────────────────┘
```

### 3.6 Pantalla: Métricas

```
┌─────────────────────────────────────────────────────────────────┐
│  MÉTRICAS                          Últimas 24h | 7d | 30d       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────┐  ┌─────────────────────────┐      │
│  │    TAREAS POR HORA      │  │   TIEMPO DE RESPUESTA   │      │
│  │    ▁▂▃▅▇█▇▅▃▂▁        │  │    ──────── 2.3s avg    │      │
│  │    Pico: 45 tareas/h    │  │    P95: 4.5s            │      │
│  └─────────────────────────┘  └─────────────────────────┘      │
│                                                                  │
│  ┌─────────────────────────┐  ┌─────────────────────────┐      │
│  │   TASA DE ÉXITO         │  │   CONSENSO TRI-AGENTE   │      │
│  │    ████████░░ 94%       │  │    █████████░ 98%       │      │
│  │    6 errores hoy        │  │    2 rechazos hoy       │      │
│  └─────────────────────────┘  └─────────────────────────┘      │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ DISTRIBUCIÓN POR DOMINIO                                    ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │  /dev       ████████████████████ 45%                       ││
│  │  /infra     ████████████ 28%                               ││
│  │  /academico ████ 12%                                        ││
│  │  /crypto    ███ 8%                                          ││
│  │  Otros      ██ 7%                                           ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### 3.7 Pantalla: Configuración

```
┌─────────────────────────────────────────────────────────────────┐
│  CONFIGURACIÓN                                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ SISTEMA                                                     ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │  Versión:        2.4.0                                      ││
│  │  Entorno:        production                                 ││
│  │  Gateway:        127.0.0.1:18789 ✓                         ││
│  │  Ollama:         127.0.0.1:11434 ✓                         ││
│  │  Redis:          127.0.0.1:6379 ✓                          ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ MODELOS IA                                                  ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │  Coordinación:   Claude Opus 4.6                           ││
│  │  Ejecución:      Claude Sonnet 4.6                         ││
│  │  Local:          Ollama llama3.2:3b                        ││
│  │  Fallback:       GPT-4o-mini                               ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ SEGURIDAD                                                   ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │  Sandbox:        ✓ Activado                                ││
│  │  Aprobación:     ✓ Requerida para acciones destructivas    ││
│  │  Tokens:         •••••••••• (8 configurados)               ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  [Backup Now] [Restart Services] [View Full Config]             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. API del Dashboard

### 4.1 Endpoints WebSocket

```typescript
// Conexión al Gateway existente
ws://127.0.0.1:18789

// Mensajes del dashboard
interface DashboardMessage {
  type: 'dashboard_subscribe' | 'dashboard_state' | 'dashboard_action';
  payload: {
    screens?: ('system' | 'agents' | 'tasks' | 'memory' | 'logs' | 'metrics')[];
    action?: 'restart_agent' | 'cancel_task' | 'update_config';
    target?: string;
  };
}
```

### 4.2 Endpoints HTTP (Nuevos)

```typescript
// Puerto 18790 - Mission Control API

GET  /api/system/status      // Estado del sistema
GET  /api/agents             // Lista de agentes
GET  /api/agents/:id         // Detalle de agente
GET  /api/tasks              // Lista de tareas
POST /api/tasks              // Crear tarea
GET  /api/memory/search      // Buscar en memoria
GET  /api/logs               // Logs filtrados
GET  /api/metrics            // Métricas agregadas
GET  /api/config             // Configuración actual
POST /api/config/backup      // Crear backup
```

---

## 5. Seguridad

### 5.1 Principios

| Principio | Implementación |
|-----------|----------------|
| **Solo localhost** | 127.0.0.1:18790 |
| **Autenticación** | Token desde Gateway |
| **Sin exposición** | Firewall bloquea puerto externo |
| **Audit logging** | Todas las acciones se registran |

### 5.2 Configuración de Firewall

```bash
# Asegurar que Mission Control NO es accesible externamente
sudo ufw deny 18790
sudo ufw allow from 127.0.0.1 to any port 18790

# Verificar
sudo ufw status | grep 18790
# Debe mostrar: DENY para externo, ALLOW para localhost
```

### 5.3 Acceso Remoto (VPS)

```bash
# Opción 1: SSH Tunnel
ssh -L 18790:localhost:18790 usuario@vps

# Opción 2: VPN (WireGuard/Tailscale)
# Configurar VPN y acceder via IP privada

# ❌ NUNCA: Exponer puerto directamente a internet
```

---

## 6. Plan de Implementación

### 6.1 Fase 1: MVP (2-3 días)

| Tarea | Tiempo |
|-------|--------|
| Setup Next.js + Tailwind + shadcn | 2h |
| Pantalla Sistema (básica) | 4h |
| Pantalla Logs (streaming) | 3h |
| Conexión WebSocket | 3h |
| Autenticación con Gateway | 2h |

### 6.2 Fase 2: Core (3-4 días)

| Tarea | Tiempo |
|-------|--------|
| Pantalla Agentes | 4h |
| Pantalla Tareas (Kanban) | 6h |
| Pantalla Memoria | 4h |
| APIs REST internas | 4h |

### 6.3 Fase 3: Avanzado (2-3 días)

| Tarea | Tiempo |
|-------|--------|
| Pantalla Métricas (gráficos) | 4h |
| Pantalla Configuración | 3h |
| Acciones remotas (restart, etc.) | 4h |
| Testing y hardening | 4h |

### 6.4 Estructura de Directorios

```
mission-control/
├── src/
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   ├── agents/
│   │   ├── tasks/
│   │   ├── memory/
│   │   ├── logs/
│   │   ├── metrics/
│   │   └── config/
│   ├── components/
│   │   ├── ui/           # shadcn components
│   │   ├── layout/
│   │   └── charts/
│   ├── lib/
│   │   ├── api.ts
│   │   ├── websocket.ts
│   │   └── auth.ts
│   └── stores/
│       └── dashboard.ts
├── public/
├── .env.local
├── next.config.js
└── package.json
```

---

## 7. Integración con PM2

### 7.1 ecosystem.config.js

```javascript
module.exports = {
  apps: [
    {
      name: 'openclaw-gateway',
      script: 'dist/gateway.js',
      cwd: '/home/user/openclaw',
      env: {
        PORT: 18789,
        NODE_ENV: 'production'
      }
    },
    {
      name: 'mission-control',
      script: 'node_modules/next/dist/bin/next',
      args: 'start -p 18790',
      cwd: '/home/user/mission-control',
      env: {
        NEXT_TELEMETRY_DISABLED: '1',
        GATEWAY_URL: 'ws://127.0.0.1:18789'
      }
    }
  ]
};
```

### 7.2 Comandos

```bash
# Iniciar todo
pm2 start ecosystem.config.js

# Ver estado
pm2 status

# Logs específicos
pm2 logs mission-control

# Reiniciar dashboard
pm2 restart mission-control
```

---

## 8. Checklist de Despliegue

### 8.1 Pre-despliegue

- [ ] Next.js compilado (`npm run build`)
- [ ] Variables de entorno configuradas
- [ ] Token de Gateway obtenido
- [ ] Firewall configurado

### 8.2 Post-despliegue

- [ ] Dashboard accesible en localhost:18790
- [ ] WebSocket conectando a Gateway
- [ ] Logs streaming funcionando
- [ ] Métricas actualizándose
- [ ] PM2 status shows both services online

### 8.3 Verificación de Seguridad

```bash
# Verificar que NO es accesible externamente
curl http://TU_IP_PUBLICA:18790
# Debe fallar o timeout

# Verificar que SÍ es accesible localmente
curl http://127.0.0.1:18790
# Debe responder con HTML
```

---

## 9. Alternativas Pre-construidas

Si no se desea construir desde cero, se puede evaluar:

| Proyecto | Ventajas | Desventajas |
|----------|----------|-------------|
| **Autensa** | Listo para usar | No adaptado a OPENCLAW |
| **OpenClaw Mission Control** | Integración nativa | Requiere adaptación |

**Recomendación:** Construir propio para máxima integración con arquitectura OPENCLAW.

---

**Documento:** Mission Control - Dashboard de Operaciones
**Ubicación:** `docs/13-OPERACIONES/05-mission-control.md`
**Versión:** 1.0
**Fecha:** 2026-03-10
