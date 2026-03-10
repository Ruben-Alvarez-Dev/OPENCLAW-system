# Arquitectura de Puertos y Red

**ID:** DOC-SIS-PUE-001
**Versión:** 2.0
**Fecha:** 2026-03-10
**Estado:** Documentación Técnica

---

## Resumen

Este documento describe la arquitectura de puertos del OPENCLAW-system para el **Concilio Tri-Agente** (Director + Ejecutor + Archivador).

---

## 1. Diagrama de Arquitectura Tri-Agente

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              RED LOCAL (127.0.0.1)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    GATEWAY FASTIFY (18789)                           │   │
│  │                    ═══════════════════════                           │   │
│  │  • Punto de entrada único para comunicación                          │   │
│  │  • HTTP + WebSocket                                                   │   │
│  │  • Autenticación con token                                           │   │
│  │  • Routing de mensajes entre componentes                             │   │
│  │  • Bind: 127.0.0.1 (loopback only)                                   │   │
│  └──────────────────────────────┬──────────────────────────────────────┘   │
│                                 │                                           │
│                    ┌────────────┴────────────┐                              │
│                    │     Redis Pub/Sub        │                              │
│                    └────────────┬────────────┘                              │
│                                 │                                           │
│    ┌────────────────────────────┼────────────────────────────┐             │
│    │                            │                            │             │
│    ▼                            ▼                            ▼             │
│  ┌──────────────┐       ┌──────────────┐            ┌──────────────┐      │
│  │  DIRECTOR    │       │   EJECUTOR   │            │  ARCHIVADOR  │      │
│  │  Puerto:8081 │◄──────┤ Puerto:8082  │◄───────────┤ Puerto:8083  │      │
│  │  (Opus 4.6)  │       │  (Sonnet 4.6)│            │ (Haiku 4.5)  │      │
│  │              │       │              │            │              │      │
│  │ PM2: sis-    │       │ PM2: sis-    │            │ PM2: sis-    │      │
│  │   director   │       │   ejecutor   │            │  archivador  │      │
│  └──────────────┘       └──────────────┘            └──────────────┘      │
│        │                      │                           │                 │
│        │                      │                           │                 │
│        └──────────────────────┴───────────────────────────┘                 │
│                               │                                             │
│                    Comunicación via Redis Pub/Sub                           │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  REDIS (6379) - Message Broker                                       │  │
│  │  • Pub/Sub para comunicación inter-agente                           │  │
│  │  • Colas BullMQ para tareas async                                   │  │
│  │  • Bind: 127.0.0.1                                                   │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                 │
                                 │ 127.0.0.1:11434
                                 ▼
                        ┌──────────────┐
                        │    OLLAMA    │
                        │  (Inferencia)│
                        └──────────────┘
```

---

## 2. Puertos del Sistema

### 2.1 Puertos del Concilio Tri-Agente

| Puerto | Servicio | Bind | Protocolo | Propósito |
|--------|----------|------|-----------|-----------|
| **18789** | Gateway | 127.0.0.1 | HTTP/WS | Punto de entrada único |
| **8081** | Director | 127.0.0.1 | HTTP | Agente coordinador |
| **8082** | Ejecutor | 127.0.0.1 | HTTP | Agente productor |
| **8083** | Archivador | 127.0.0.1 | HTTP | Agente validador/memoria |
| **6379** | Redis | 127.0.0.1 | TCP | Message broker Pub/Sub |
| **11434** | Ollama | 127.0.0.1 | HTTP | Inferencia LLM local |

### 2.2 Puertos de Observabilidad (Opcionales)

| Puerto | Servicio | Bind | Protocolo | Notas |
|--------|----------|------|-----------|-------|
| 9090 | Prometheus | 127.0.0.1 | HTTP | Métricas |
| 3000 | Grafana | 127.0.0.1 | HTTP | Dashboards |
| 9229 | Node.js Debug | 127.0.0.1 | TCP | Solo con `--inspect` |

### 2.3 Puertos NO Utilizados

| Puerto | Uso Común | Por qué NO se usa |
|--------|-----------|-------------------|
| 80/443 | Web Server | Solo via Nginx proxy si se expone |
| 8080 | HTTP Proxy | Gateway usa 18789 |
| 5432 | PostgreSQL | SQLite/LanceDB suficientes |

---

## 3. Flujo de Comunicación Tri-Agente

### 3.1 Secuencia de Procesamiento

```
1. Usuario envía mensaje
   │
   ├── Telegram/Discord/CLI → Gateway (18789)
   │
2. Gateway enruta al Director
   │
   ├── Gateway → Redis PUBLISH → Director (8081)
   │   └── Director planea, delega, valida
   │
3. Director delega al Ejecutor
   │
   ├── Director → Redis PUBLISH → Ejecutor (8082)
   │   └── Ejecutor ejecuta, produce, genera
   │
4. Ejecutor pasa al Archivador
   │
   ├── Ejecutor → Redis PUBLISH → Archivador (8083)
   │   └── Archivador valida, documenta, memoriza
   │
5. Archivador confirma al Director
   │
   ├── Archivador → Redis PUBLISH → Director (8081)
   │   └── Director entrega resultado final
   │
6. Director responde al Gateway
   │
   └── Director → Gateway → Usuario
```

### 3.2 Formato de Mensaje Redis Pub/Sub

```typescript
interface MensajeConcilio {
  id: string;           // UUID único
  origen: string;       // "director" | "ejecutor" | "archivador" | "gateway"
  destino: string;      // "director" | "ejecutor" | "archivador" | "todos"
  tipo: string;         // "tarea" | "resultado" | "validacion" | "error"
  payload: unknown;     // Contenido del mensaje
  timestamp: number;    // Unix timestamp
  sesionId: string;     // ID de sesión para tracking
}
```

---

## 4. Configuración de Firewall

### 4.1 Reglas UFW (Ubuntu)

```bash
# ⚠️ IMPORTANTE: El Gateway (18789) NO debe exponerse a internet
# Solo permitir desde localhost y red Tailscale (100.x.x.x)
sudo ufw allow from 127.0.0.1 to any port 18789 proto tcp comment 'Gateway localhost'
sudo ufw allow from 100.0.0.0/8 to any port 18789 proto tcp comment 'Gateway Tailscale'

# Redis, Ollama, Agentes: SOLO localhost
# NO añadir reglas para 6379, 8081, 8082, 8083, 11434

# Verificar que NO hay reglas permisivas
sudo ufw status numbered | grep -E "6379|8081|8082|8083|11434|18789"
```

### 4.2 Reglas macOS Firewall

```bash
# Verificar estado
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# Los servicios en loopback (127.0.0.1) no requieren reglas explícitas
# PF puede configurarse para bloquear accesos externos si es necesario
```

---

## 5. Verificación de Puertos

### 5.1 Comandos de Verificación

```bash
# Verificar Gateway escuchando
ss -tlnp | grep 18789
# Esperado: LISTEN 0  128  127.0.0.1:18789  0.0.0.0:*

# Verificar Ollama escuchando
ss -tlnp | grep 11434
# Esperado: LISTEN 0  128  127.0.0.1:11434  0.0.0.0:*

# Verificar que NO hay puertos expuestos en 0.0.0.0
ss -tlnp | grep "0.0.0.0"
# NO debe mostrar 18789 ni 11434

# Test de conectividad Gateway
curl -v http://127.0.0.1:18789/health
# Esperado: HTTP response o upgrade request

# Test de conectividad Ollama
curl http://127.0.0.1:11434/api/version
# Esperado: {"version":"0.x.x"}
```

### 5.2 Test de Seguridad

```bash
#!/bin/bash
# Verificar que servicios NO están expuestos externamente

echo "=== VERIFICACIÓN DE SEGURIDAD DE PUERTOS ==="

# Obtener IP pública
IP_PUBLICA=$(curl -s ifconfig.me)

# Test Gateway desde "fuera" (timeout si no expuesto)
echo "Test Gateway externo..."
timeout 2 curl -s http://${IP_PUBLICA}:18789/health && \
  echo "❌ Gateway EXPUESTO" || echo "✅ Gateway seguro (no expuesto)"

# Test Ollama desde "fuera"
echo "Test Ollama externo..."
timeout 2 curl -s http://${IP_PUBLICA}:11434/api/version && \
  echo "❌ Ollama EXPUESTO" || echo "✅ Ollama seguro (no expuesto)"

# Verificar bind correcto
echo ""
echo "Bind de servicios:"
ss -tlnp | grep -E "18789|11434"
```

---

## 6. Configuración de ecosystem.config.js

```javascript
// ecosystem.config.js - Configuración correcta de puertos
module.exports = {
  apps: [
    {
      name: 'sis-gateway',
      script: 'dist/cli/openclaw.js',
      args: 'gateway start --port 18789',
      // Gateway es el ÚNICO que especifica puerto
      env: {
        GATEWAY_URL: 'ws://127.0.0.1:18789'
      }
    },
    {
      name: 'sis-director',
      script: 'dist/cli/openclaw.js',
      args: 'gear start director --gateway ws://127.0.0.1:18789',
      // Director NO tiene puerto HTTP, se conecta al Gateway
    },
    {
      name: 'sis-ejecutor',
      script: 'dist/cli/openclaw.js',
      args: 'gear start ejecutor --gateway ws://127.0.0.1:18789',
      // Ejecutor NO tiene puerto HTTP, se conecta al Gateway
    },
    {
      name: 'sis-archivador',
      script: 'dist/cli/openclaw.js',
      args: 'gear start archivador --gateway ws://127.0.0.1:18789',
      // Archivador NO tiene puerto HTTP, se conecta al Gateway
    }
  ]
};
```

---

## 7. Acceso Remoto Seguro

### 7.1 SSH Tunneling (Recomendado)

```bash
# En máquina local
ssh -L 18789:127.0.0.1:18789 usuario@servidor-remoto

# Ahora puedes acceder localmente:
# ws://127.0.0.1:18789 (tunelado al servidor)
```

### 7.2 Tailscale (Recomendado)

```bash
# Instalar Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Conectar
tailscale up

# Acceder via IP de Tailscale
# ws://100.x.y.z:18789 (solo accesible desde tu red Tailscale)
```

### 7.3 VPN (Alternativa)

Configurar WireGuard o OpenVPN para acceso seguro.

---

## 8. Troubleshooting de Conectividad

### 8.1 Gateway No Responde

```bash
# Verificar que está corriendo
pm2 status | grep gateway

# Ver logs
pm2 logs sis-gateway --lines 50

# Verificar puerto
ss -tlnp | grep 18789

# Si no escucha, reiniciar
pm2 restart sis-gateway
```

### 8.2 Agente No Conecta

```bash
# Verificar que Gateway está activo primero
curl http://127.0.0.1:18789/health

# Verificar logs del agente
pm2 logs sis-director --lines 50

# Verificar configuración de GATEWAY_URL
pm2 env 0 | grep GATEWAY_URL
```

### 8.3 Puerto Ocupado

```bash
# Ver qué proceso usa el puerto
sudo lsof -i :18789

# Si es proceso zombie, matar
sudo kill -9 $(sudo lsof -t -i :18789)

# Reiniciar servicio
pm2 restart sis-gateway
```

---

## 9. Referencias Cruzadas

- **Instalación:** [12-IMPLEMENTACION/01-instalacion.md](../12-IMPLEMENTACION/01-instalacion.md)
- **Seguridad:** [11-SEGURIDAD/00-seguridad.md](../11-SEGURIDAD/00-seguridad.md)
- **Operaciones:** [13-OPERACIONES/00-gestion-servicios.md](../13-OPERACIONES/00-gestion-servicios.md)
- **Troubleshooting:** [99-ANEXOS/E-TROUBLESHOOTING.md](../99-ANEXOS/E-TROUBLESHOOTING.md)

---

**Documento:** Arquitectura de Puertos y Red
**ID:** DOC-SIS-PUE-001
**Versión:** 1.0
**Fecha:** 2026-03-10
