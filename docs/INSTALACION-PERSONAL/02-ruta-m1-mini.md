# Ruta de Instalación: M1 Mac Mini Standalone

**ID:** DOC-PER-INS-001
**Versión:** 1.0
**Fecha:** 2026-03-10
**Hardware:** Mac Mini M1 16GB + NVMe 4TB Thunderbolt 4

---

## Resumen

Instalación completa de OPENCLAW-system en Mac Mini M1 como servidor standalone. Aprovecha el NVMe externo para almacenamiento principal y Metal para aceleración GPU.

**Tiempo estimado:** 3-4 horas
**Dificultad:** Media

---

## Arquitectura Objetivo

```
Mac Mini M1 (Standalone)
│
├── /Volumes/NVMe-4TB/openclaw/          ← Directorio principal
│   ├── gateway/                          ← WebSocket gateway
│   ├── orquestador/                      ← Tri-agente SIS
│   ├── catedraticos/                     ← 6 jefes
│   ├── especialistas/                    ← Unidades tri-agente
│   ├── memoria/                          ← Vector DB + Redis
│   ├── conocimiento/                     ← Motor 5 capas
│   ├── logs/                             ← Auditoría
│   └── mission-control/                  ← Dashboard
│
├── ~/.ollama/models                      ← Modelos en SSD interno
│
└── ~/Library/LaunchAgents/               ← Servicios macOS
```

---

## Fase 1: Preparación del Sistema

### 1.1 Verificar Requisitos

```bash
# Verificar macOS versión (mínimo 14.0 Sonoma)
sw_vers

# Verificar arquitectura
uname -m  # debe mostrar: arm64

# Verificar NVMe montado
ls /Volumes/ | grep -i nvme

# Verificar espacio
df -h /Volumes/NVMe-4TB  # Ajustar nombre real
```

### 1.2 Instalar Homebrew (si no existe)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 1.3 Instalar Dependencias

```bash
# Node.js 22+
brew install node@22
echo 'export PATH="/opt/homebrew/opt/node@22/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# pnpm
brew install pnpm

# Git (suele venir)
brew install git

# Redis
brew install redis

# Otras herramientas
brew install jq wget curl
```

### 1.4 Configurar NVMe

```bash
# Crear estructura de directorios
export OPENCLAW_ROOT="/Volumes/NVMe-4TB/openclaw"
mkdir -p $OPENCLAW_ROOT/{gateway,orquestador,catedraticos,especialistas,memoria,conocimiento,logs,mission-control,backups}

# Configurar permisos
chmod -R 755 $OPENCLAW_ROOT

# Añadir a ~/.zshrc
echo "export OPENCLAW_ROOT=\"/Volumes/NVMe-4TB/openclaw\"" >> ~/.zshrc
source ~/.zshrc
```

---

## Fase 2: Ollama (LLM Local)

### 2.1 Instalar Ollama

```bash
# Descargar e instalar
curl -fsSL https://ollama.com/install.sh | sh

# O manualmente desde https://ollama.com/download
```

### 2.2 Configurar Modelos

```bash
# Modelos base (aprox 8GB total)
ollama pull llama3.2:3b           # ~2GB - Tareas rápidas
ollama pull qwen2.5:7b            # ~4.5GB - Código/lógica
ollama pull nomic-embed-text      # ~274MB - Embeddings

# Verificar GPU Metal
ollama run llama3.2:3b --verbose
# Debe mostrar: GPU Apple M1 detected
```

### 2.3 Configurar Ollama como Servicio

```bash
# Ollama se instala como servicio automáticamente
# Verificar estado
brew services list | grep ollama

# Configurar variables de entorno
echo 'export OLLAMA_HOST="127.0.0.1:11434"' >> ~/.zshrc
echo 'export OLLAMA_MODELS="~/.ollama/models"' >> ~/.zshrc
source ~/.zshrc
```

---

## Fase 3: Redis

### 3.1 Configurar Redis

```bash
# Iniciar Redis
brew services start redis

# Verificar
redis-cli ping  # debe responder: PONG

# Configurar persistencia
redis-cli CONFIG SET appendonly yes
redis-cli CONFIG SET appendfsync everysec
```

### 3.2 Seguridad Redis

```bash
# Establecer contraseña
redis-cli CONFIG SET requirepass "$(openssl rand -hex 32)"

# Guardar configuración
redis-cli CONFIG REWRITE

# Probar conexión con auth
redis-cli -a "$(cat ~/.redis_pass 2>/dev/null || echo 'tu-password')" ping
```

---

## Fase 4: Gateway WebSocket

### 4.1 Crear Proyecto Gateway

```bash
cd $OPENCLAW_ROOT/gateway

# Inicializar proyecto
pnpm init
pnpm add fastify @fastify/websocket @fastify/cors dotenv

# Crear estructura
mkdir -p src/{routes,middleware,utils}
```

### 4.2 Código Gateway Básico

```bash
cat > $OPENCLAW_ROOT/gateway/src/index.js << 'EOF'
import Fastify from 'fastify';
import websocket from '@fastify/websocket';
import cors from '@fastify/cors';

const fastify = Fastify({ logger: true });

await fastify.register(websocket);
await fastify.register(cors, { origin: '*' });

// Health check
fastify.get('/health', async () => ({ status: 'ok', timestamp: Date.now() }));

// WebSocket principal
fastify.register(async function (fastify) {
  fastify.get('/ws', { websocket: true }, (connection, req) => {
    connection.socket.on('message', (message) => {
      // Aquí va el routing hacia orquestador
      connection.socket.send(JSON.stringify({
        type: 'ack',
        message: 'Message received'
      }));
    });
  });
});

const start = async () => {
  try {
    await fastify.listen({ port: 18789, host: '127.0.0.1' });
    console.log('Gateway running on http://127.0.0.1:18789');
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();
EOF
```

### 4.3 Configurar Package.json

```bash
cat > $OPENCLAW_ROOT/gateway/package.json << 'EOF'
{
  "name": "openclaw-gateway",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "node src/index.js",
    "dev": "node --watch src/index.js"
  }
}
EOF
```

---

## Fase 5: Orquestador SIS (Tri-agente)

### 5.1 Estructura Tri-agente

```bash
cd $OPENCLAW_ROOT/orquestador
pnpm init
pnpm add ollama-ai-provider ai dotenv

mkdir -p src/{director,ejecutor,archivador,consenso}
```

### 5.2 Director

```bash
cat > $OPENCLAW_ROOT/orquestador/src/director/index.js << 'EOF'
// Director: Planificación y delegación
import { ollama } from 'ollama-ai-provider';
import { generateText } from 'ai';

const model = ollama('llama3.2:3b');

export async function planificar(solicitud) {
  const prompt = `
Eres el Director del sistema OPENCLAW.
Analiza esta solicitud y determina:
1. Dominio (DES, INF, HOS, ACA, CRI, FIN, DEP, IDI, GEN)
2. Tareas necesarias
3. Recursos requeridos

Solicitud: ${solicitud}

Responde en JSON con: { dominio, tareas: [], recursos: [] }
`;

  const { text } = await generateText({ model, prompt });
  return JSON.parse(text);
}

export async function delegar(plan) {
  // Routing hacia catedrático correspondiente
  return {
    destino: `JEF-${plan.dominio}`,
    instrucciones: plan.tareas,
    recursos: plan.recursos
  };
}
EOF
```

### 5.3 Ejecutor

```bash
cat > $OPENCLAW_ROOT/orquestador/src/ejecutor/index.js << 'EOF'
// Ejecutor: Ejecución de tareas
import { ollama } from 'ollama-ai-provider';
import { generateText } from 'ai';

const model = ollama('qwen2.5:7b');

export async function ejecutar(instrucciones, contexto) {
  const prompt = `
Eres el Ejecutor del sistema OPENCLAW.
Ejecuta las siguientes instrucciones con el contexto dado.

Instrucciones: ${JSON.stringify(instrucciones)}
Contexto: ${JSON.stringify(contexto)}

Proporciona el resultado de la ejecución.
`;

  const { text } = await generateText({ model, prompt });
  return text;
}
EOF
```

### 5.4 Archivador

```bash
cat > $OPENCLAW_ROOT/orquestador/src/archivador/index.js << 'EOF'
// Archivador: Validación y documentación
import { ollama } from 'ollama-ai-provider';
import { generateText } from 'ai';

const model = ollama('llama3.2:3b');

export async function validar(resultado, plan) {
  const prompt = `
Eres el Archivador del sistema OPENCLAW.
Valida que el resultado cumple con el plan original.

Plan original: ${JSON.stringify(plan)}
Resultado: ${resultado}

Responde en JSON con:
{
  "valido": boolean,
  "errores": [],
  "mejoras": [],
  "confianza": 0-100
}
`;

  const { text } = await generateText({ model, prompt });
  return JSON.parse(text);
}

export async function documentar(sesion) {
  // Guardar en memoria del sistema
  return { documentado: true, sesionId: sesion.id };
}
EOF
```

### 5.5 Consenso Tri-agente

```bash
cat > $OPENCLAW_ROOT/orquestador/src/consenso/index.js << 'EOF'
// Consenso: Coordinación de tri-agente
import { planificar, delegar } from '../director/index.js';
import { ejecutar } from '../ejecutor/index.js';
import { validar, documentar } from '../archivador/index.js';

export async function procesarSolicitud(solicitud) {
  const sesionId = `SES-${Date.now()}`;

  console.log(`[${sesionId}] Director: Planificando...`);
  const plan = await planificar(solicitud);
  const delegacion = await delegar(plan);

  console.log(`[${sesionId}] Ejecutor: Ejecutando...`);
  const resultado = await ejecutar(delegacion.instrucciones, {
    solicitud,
    plan,
    delegacion
  });

  console.log(`[${sesionId}] Archivador: Validando...`);
  const validacion = await validar(resultado, plan);

  if (validacion.valido || validacion.confianza >= 70) {
    await documentar({ id: sesionId, solicitud, plan, resultado, validacion });
    return {
      exito: true,
      resultado,
      validacion,
      sesionId
    };
  }

  // Retry si no pasa validación
  return {
    exito: false,
    errores: validacion.errores,
    sesionId
  };
}
EOF
```

---

## Fase 6: Mission Control

### 6.1 Crear Proyecto Next.js

```bash
cd $OPENCLAW_ROOT/mission-control

npx create-next-app@14 . --typescript --tailwind --eslint --app --src-dir
# Responder: Yes a todo, No a turbopack

pnpm add @shadcn/ui
npx shadcn-ui@latest init
```

### 6.2 Pantallas Básicas

```bash
# Crear páginas
mkdir -p src/app/{sistema,agentes,tareas,logs,metricas}

# Página sistema
cat > src/app/sistema/page.tsx << 'EOF'
export default function SistemaPage() {
  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">Estado del Sistema</h1>
      <div className="grid grid-cols-3 gap-4">
        <StatusCard title="Gateway" status="online" port={18789} />
        <StatusCard title="Ollama" status="online" port={11434} />
        <StatusCard title="Redis" status="online" port={6379} />
      </div>
    </div>
  );
}

function StatusCard({ title, status, port }: { title: string; status: string; port: number }) {
  return (
    <div className="border rounded-lg p-4">
      <h2 className="font-semibold">{title}</h2>
      <p className="text-sm text-gray-500">Port: {port}</p>
      <span className={`inline-block px-2 py-1 rounded text-xs ${status === 'online' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
        {status}
      </span>
    </div>
  );
}
EOF
```

---

## Fase 7: Servicios macOS (launchd)

### 7.1 Gateway Service

```bash
cat > ~/Library/LaunchAgents/com.openclaw.gateway.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.gateway</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/pnpm</string>
        <string>start</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Volumes/NVMe-4TB/openclaw/gateway</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Volumes/NVMe-4TB/openclaw/logs/gateway.log</string>
    <key>StandardErrorPath</key>
    <string>/Volumes/NVMe-4TB/openclaw/logs/gateway.error.log</string>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.openclaw.gateway.plist
```

### 7.2 Redis Service (ya configurado con brew)

```bash
brew services start redis
```

---

## Fase 8: Verificación

### 8.1 Smoke Tests

```bash
# Gateway
curl http://127.0.0.1:18789/health
# Esperado: {"status":"ok","timestamp":...}

# Ollama
curl http://127.0.0.1:11434/api/version
# Esperado: {"version":"0.x.x"...}

# Redis
redis-cli ping
# Esperado: PONG

# Mission Control
curl http://127.0.0.1:18790
# Esperado: HTML del dashboard
```

### 8.2 Prueba End-to-End

```bash
# Test básico del orquestador
curl -X POST http://127.0.0.1:18789/api/solicitud \
  -H "Content-Type: application/json" \
  -d '{"mensaje": "/dev crear función fibonacci"}'
```

---

## Configuración de Red

### Puertos Locales (127.0.0.1)

| Puerto | Servicio | Acceso |
|--------|----------|--------|
| 18789 | Gateway | Localhost only |
| 18790 | Mission Control | Localhost only |
| 11434 | Ollama | Localhost only |
| 6379 | Redis | Localhost only |

### Exposición vía Tailscale

```bash
# Si quieres acceso desde otros dispositivos Tailscale
# Editar servicios para escuchar en 0.0.0.0 o IP Tailscale específica

# Obtener IP Tailscale del Mac Mini
tailscale ip -4
```

---

## Backup

### Script de Backup

```bash
cat > $OPENCLAW_ROOT/scripts/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/Volumes/NVMe-4TB/openclaw/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Backup Redis
redis-cli BGSAVE
cp /opt/homebrew/var/db/redis/dump.rdb "$BACKUP_DIR/redis_$DATE.rdb"

# Backup configuración
tar -czf "$BACKUP_DIR/config_$DATE.tar.gz" \
  --exclude='node_modules' \
  --exclude='.next' \
  /Volumes/NVMe-4TB/openclaw/*/package.json \
  /Volumes/NVMe-4TB/openclaw/*/src

# Limpiar backups antiguos (>30 días)
find $BACKUP_DIR -type f -mtime +30 -delete

echo "Backup completado: $DATE"
EOF

chmod +x $OPENCLAW_ROOT/scripts/backup.sh
```

### Cron Job

```bash
# Backup diario a las 3am
(crontab -l 2>/dev/null; echo "0 3 * * * /Volumes/NVMe-4TB/openclaw/scripts/backup.sh") | crontab -
```

---

## Checklist de Verificación Final

Antes de dar por completada la instalación, verifica:

### Servicios Core
- [ ] **Redis responde**: `redis-cli ping` → `PONG`
- [ ] **Gateway health**: `curl http://127.0.0.1:18789/health` → `{"status":"ok"}`
- [ ] **Director online**: `curl http://127.0.0.1:8081/health`
- [ ] **Ejecutor online**: `curl http://127.0.0.1:8082/health`
- [ ] **Archivador online**: `curl http://127.0.0.1:8083/health`

### LLM (Ollama)
- [ ] **Ollama running**: `ollama list` muestra modelos instalados
- [ ] **Modelo por defecto**: `ollama run llama3.2:3b "hola"` responde
- [ ] **Metal aceleración**: `ollama ps` muestra GPU usage

### Memoria
- [ ] **LanceDB**: Directorio `/Volumes/NVMe-4TB/openclaw/memoria/lancedb` existe
- [ ] **Permisos**: `ls -la /Volumes/NVMe-4TB/openclaw/memoria` muestra tu usuario

### Seguridad
- [ ] **Gateway NO expuesto**: `curl http://$(ipconfig getifaddr en0):18789/health` desde otro dispositivo → RECHAZADO
- [ ] **PM2 startup**: `pm2 startup` configurado

### Backup
- [ ] **Script existe**: `ls -la /Volumes/NVMe-4TB/openclaw/scripts/backup.sh`
- [ ] **Cron configurado**: `crontab -l | grep backup`

### Tailscale (opcional)
- [ ] **Tailscale IP**: `tailscale ip -4` muestra IP 100.x.x.x
- [ ] **Acceso remoto**: Desde otro dispositivo Tailscale, `curl http://100.x.x.x:18789/health` funciona

---

## Próximos Pasos

1. **Integrar con LMStudio Link** del MacBook Pro para modelos grandes
2. **Configurar acceso Tailscale** para dispositivos móviles
3. **Implementar catedráticos** específicos
4. **Añadir especialistas** por demanda

---

**Documento:** Ruta M1 Mini Standalone
**Ubicación:** `docs/INSTALACION-PERSONAL/01-ruta-m1-mini.md`
