# Capacidades y Experiencia de Uso - OPENCLAW Personal

**ID:** DOC-PER-CAP-001
**Versión:** 1.0
**Fecha:** 2026-03-10

---

## Capacidades del Sistema Instalado

### Resumen Ejecutivo

OPENCLAW-system transformará tu Mac Mini en un **sistema multi-agente inteligente** capaz de:

1. **Procesar solicitudes en lenguaje natural** → routed automáticamente al especialista correcto
2. **Ejecutar tareas complejas** con validación tri-agente (Director → Ejecutor → Archivador)
3. **Aprender de cada interacción** → memoria persistente multicapa
4. **Escalar bajo demanda** → integración con MacBook Pro para modelos grandes
5. **Acceso desde cualquier dispositivo** → vía Tailscale VPN

---

## Capacidades Detalladas por Componente

### 1. Gateway (Puerto 18789)

| Capacidad | Descripción |
|-----------|-------------|
| WebSocket bidireccional | Comunicación en tiempo real |
| REST API | Integración con apps externas |
| Autenticación API Key | Seguridad por clave |
| Rate limiting | 100 req/min por IP |
| Health monitoring | `/health` endpoint |

### 2. Orquestador SIS (Tri-agente)

| Capacidad | Descripción |
|-----------|-------------|
| **Director** | Analiza solicitudes, detecta dominio, planifica tareas |
| **Ejecutor** | Ejecuta tareas, genera código, procesa información |
| **Archivador** | Valida resultados, documenta, actualiza memoria |

**Flujo de una solicitud:**

```
Usuario: "/dev crear función fibonacci en Python"

Director analiza:
├── Dominio detectado: DES (desarrollo)
├── Tareas: [crear_funcion, documentar, test]
└── Routing: JEF-ING → ESP-DES

Ejecutor ejecuta:
├── Genera código Python
├── Añade docstring
└── Crea test básico

Archivador valida:
├── Código sintácticamente correcto ✓
├── Test pasa ✓
├── Calidad: 85/100
└── Documentado en memoria

Respuesta al usuario:
"Función fibonacci creada. Incluye docstring y test.
 Calidad: 85/100. Guardado para referencia futura."
```

### 3. Catedráticos (6 Jefes de Dominio)

| Catedrático | Domains | Qué puede hacer |
|-------------|---------|-----------------|
| **CKO** (Conocimiento) | ACA, GEN | Investigar, documentar, explicar conceptos |
| **CEngO** (Ingeniería) | DES, INF | Código, arquitectura, DevOps |
| **COO** (Operaciones) | HOS | Procesos, workflows, automatización |
| **CHO** (RRHH) | DEP | Fábrica de agentes, gestión talento |
| **CSRO** (Relaciones) | CRI, FIN | Estrategia, inversiones, análisis |
| **CCO** (Comunicación) | IDI | Traducción, aprendizaje idiomas |

### 4. Especialistas (Tri-agentes por Dominio)

| Namespace | Dominio | Ejemplos de uso |
|-----------|---------|-----------------|
| `/dev` | Desarrollo | "Crear API REST", "Refactorizar código" |
| `/infra` | Infraestructura | "Configurar Docker", "Optimizar Nginx" |
| `/crypto` | Criptomonedas | "Analizar tendencia BTC", "Explicar DeFi" |
| `/inversiones` | Finanzas | "Análisis riesgo/beneficio", "Diversificar cartera" |
| `/hosteleria` | Gastronomía | "Receta para 50 personas", "Menú degustación" |
| `/academico` | Oposiciones | "Resumen tema 3", "Pregunta tipo examen" |
| `/fitness` | Deportes | "Rutina de fuerza", "Plan nutricional" |
| `/english` | Idiomas | "Corregir grammar", "Practicar conversación" |
| `/general` | General | Cualquier consulta no específica |

### 5. Memoria (4 Niveles)

```
┌─────────────────────────────────────────────────────────┐
│ NIVEL 4: MEMORIA GLOBAL                                 │
│ "El usuario prefiere respuestas concisas"               │
│ "Stack tecnológico: Node.js, Python, Rust"             │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│ NIVEL 3: MEMORIA DE DOMINIO                             │
│ DES: "Prefiere TypeScript sobre JavaScript"             │
│ FIN: "Interesado en ETFs de bajo coste"                 │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│ NIVEL 2: MEMORIA DE UNIDAD (tri-agente)                 │
│ "En la sesión anterior resolvimos X problema con Y"    │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│ NIVEL 1: MEMORIA DE AGENTE                              │
│ "Este agente tiene experiencia en React hooks"          │
└─────────────────────────────────────────────────────────┘
```

### 6. Motor de Conocimiento (5 Capas)

| Capa | Fuente | Ejemplo |
|------|--------|---------|
| 1 | Modelo base (LLM) | Conocimiento general de llama3.2 |
| 2 | Bibliotecas académicas | Libros de algoritmos en `/conocimiento/` |
| 3 | Estándares | ISO 27001, IEEE 830 |
| 4 | Memoria del sistema | Lecciones aprendidas |
| 5 | Investigación externa | Búsqueda web (con atribución) |

---

## Experiencia de Uso

### Interfaz Principal: Mission Control

Accedes desde cualquier navegador: `http://100.x.x.x:18790` (IP Tailscale del Mac Mini)

```
┌──────────────────────────────────────────────────────────────────┐
│  OPENCLAW Mission Control                          [⚙️] [🔔]    │
├──────────────────────────────────────────────────────────────────┤
│  [Sistema] [Agentes] [Tareas] [Memoria] [Logs] [Métricas] [⚙️]  │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Gateway         │  │ Ollama          │  │ Redis           │ │
│  │ 🟢 Online       │  │ 🟢 Online       │  │ 🟢 Online       │ │
│  │ Port: 18789     │  │ Models: 3       │  │ Keys: 1.2k      │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ CLUSTER STATUS                                               ││
│  │ Mac Mini: 🟢 Online (Core)                                   ││
│  │ MacBook Pro: 🟡 On-demand (LLM Server)                       ││
│  │ VPS: 🟢 Online (Gateway)                                     ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ CONVERSACIÓN                                                 ││
│  │ ┌─────────────────────────────────────────────────────────┐ ││
│  │ │ Tú: /dev crear una API REST en Fastify                   │ ││
│  │ │                                                          │ ││
│  │ │ OPENCLAW: Analizando solicitud...                        │ ││
│  │ │ Director: Dominio DES detectado.                         │ ││
│  │ │ Ejecutor: Generando código...                            │ ││
│  │ │                                                          │ ││
│  │ │ // Código generado:                                      │ ││
│  │ │ import Fastify from 'fastify';                           │ ││
│  │ │ ...                                                      │ ││
│  │ │                                                          │ ││
│  │ │ Archivador: Validación completa ✓                        │ ││
│  │ │ Calidad: 92/100                                          │ ││
│  │ └─────────────────────────────────────────────────────────┘ ││
│  │ [Escribe tu mensaje...]                         [Enviar]   ││
│  └─────────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────┘
```

### Formas de Interactuar

#### 1. Chat Web (Mission Control)
```
http://100.x.x.x:18790
```
Interfaz gráfica completa con historial, métricas y visualización.

#### 2. API REST
```bash
curl -X POST http://100.x.x.x:18789/api/solicitud \
  -H "Content-Type: application/json" \
  -H "X-API-Key: tu_api_key" \
  -d '{"mensaje": "/dev crear función fibonacci"}'
```

#### 3. WebSocket
```javascript
const ws = new WebSocket('ws://100.x.x.x:18789/ws?key=tu_api_key');
ws.send(JSON.stringify({ mensaje: "/dev help" }));
ws.onmessage = (event) => console.log(JSON.parse(event.data));
```

#### 4. CLI (Terminal)
```bash
# Crear wrapper CLI
cat > ~/bin/openclaw << 'EOF'
#!/bin/bash
API_KEY=$(cat ~/.openclaw/api_key)
curl -s http://127.0.0.1:18789/api/solicitud \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  -d "{\"mensaje\": \"$*\"}" | jq -r '.resultado'
EOF
chmod +x ~/bin/openclaw

# Uso
openclaw /dev explicar recursividad
```

---

## Casos de Uso Prácticos

### Caso 1: Desarrollo de Software

**Escenario:** Necesitas crear un microservicio.

```
Tú: /dev crear microservicio de autenticación con JWT en Node.js

OPENCLAW:
[Director analizando...]
Dominio: DES (desarrollo)
Complejidad: media
Modelo seleccionado: qwen2.5:7b

[Ejecutor trabajando...]
Generando estructura del proyecto...

📁 auth-service/
├── src/
│   ├── index.ts
│   ├── routes/
│   │   └── auth.ts
│   ├── middleware/
│   │   └── jwt.ts
│   └── utils/
│       └── token.ts
├── package.json
├── tsconfig.json
└── README.md

[Archivador validando...]
✅ Tipado correcto
✅ Manejo de errores implementado
✅ Tests incluidos
⚠️  Recomendación: Añadir rate limiting

Calidad: 88/100
¿Quieres que implemente las recomendaciones?
```

### Caso 2: Análisis de Inversiones

**Escenario:** Quieres analizar una inversión potencial.

```
Tú: /inversiones analizar ETF VOO vs VTI para largo plazo

OPENCLAW:
[Director analizando...]
Dominio: FIN (finanzas)
Tipo: análisis comparativo
Necesita: datos de mercado

[Ejecutor consultando conocimiento...]
Accediendo a información financiera...

📊 ANÁLISIS COMPARATIVO VOO vs VTI

| Métrica        | VOO      | VTI      |
|----------------|----------|----------|
| TER            | 0.03%    | 0.03%    |
| Holdings       | ~500     | ~4000    |
| Cobertura      | S&P 500  | Total US |
| Yield (approx) | 1.4%     | 1.6%     |

[Análisis basado en tu perfil de riesgo moderado]

Recomendación:
- Para simplicidad: VOO (S&P 500 puro)
- Para diversificación: VTI (exposición small-cap)

Tu cartera actual: 60% VOO + 40% VTI
Mantener proporción actual es óptimo.

[Archivador documentando...]
Análisis guardado en memoria de dominio FIN.
```

### Caso 3: Preparación Académica

**Escenario:** Estudiando para oposiciones.

```
Tú: /academico resumen del tema 3: Constitución española, derechos fundamentales

OPENCLAW:
[Director analizando...]
Dominio: ACA (académico)
Contexto: Oposiciones
Tarea: síntesis para estudio

[Ejecutor procesando...]
Consultando material académico...

📚 TEMA 3: DERECHOS FUNDAMENTALES

ESQUEMA PARA ESTUDIO:

1. ARTÍCULOS CLAVE (15-29 CE)
   ├─ Art. 15: Derecho a la vida
   ├─ Art. 16: Libertad ideológica
   ├─ Art. 17: Libertad personal
   ├─ Art. 18: Intimidad personal
   └─ Art. 20: Libertad de expresión

2. GARANTÍAS
   ├─ Preferente (art. 53.2)
   └─ Ordinaria

3. SUSPENSIÓN
   ├─ Individual: sentencia judicial
   └─ Colectiva: estado de excepción

PREGUNTAS TIPO:
1. ¿Diferencia entre derechos fundamentales y libertades públicas?
2. ¿Procedimiento para la tutela judicial efectiva?

[Archivador...]
Material guardado. ¿Quieres que genere flashcards?
```

### Caso 4: Uso desde Móvil

**Escenario:** Estás fuera y necesitas consultar algo.

```
1. Abre Tailscale en tu móvil
2. Conecta a la VPN
3. Abre navegador: http://100.x.x.x:18790
4. Escribe tu consulta

O usa la PWA:
1. Añade a pantalla de inicio
2. Icono en tu home
3. Acceso directo al sistema
```

### Caso 5: Integración con Tu Código

**Escenario:** Quieres usar OPENCLAW en tu proyecto.

```javascript
// En tu proyecto
import { OPENCLAW } from '@openclaw/sdk';

const client = new OPENCLAW({
  endpoint: 'http://100.x.x.x:18789',
  apiKey: process.env.OPENCLAW_API_KEY
});

// Solicitar código
const result = await client.solicitud('/dev crear función de validación de email');

console.log(result.codigo);
// function validateEmail(email: string): boolean { ... }

// Consultar conocimiento
const analysis = await client.solicitud('/inversiones analizar riesgo BTC');
```

---

## Flujos de Uso Típicos

### Flujo 1: Mañana de Desarrollo

```
08:00 - Abres Mission Control en el Mac
08:05 - "/dev revisar el PR pendiente"
08:15 - "/dev sugerir mejoras para el código de autenticación"
08:45 - "/dev crear tests para el nuevo módulo"
09:30 - "/dev generar documentación API"
10:00 - "/infra revisar configuración Docker"
```

### Flujo 2: Sesión de Estudio

```
19:00 - Abres Mission Control desde el iPad
19:05 - "/academico resumen tema 5"
19:30 - "/academico generar preguntas tipo examen"
20:00 - "/academico explicar concepto X del tema"
20:30 - "/english practicar vocabulario técnico"
```

### Flujo 3: Análisis Financiero

```
Sábado mañana:
- "/inversiones actualizar seguimiento cartera"
- "/crypto análisis semanal BTC/ETH"
- "/inversiones oportunidades detectadas esta semana"
- "/general generar informe resumen mensual"
```

### Flujo 4: Emergencia (Modelo Grande)

```
Tú: "/dev refactorizar este sistema legacy complejo"
    [Detectado: complejidad alta]

OPENCLAW:
Detectada complejidad alta.
Activando MacBook Pro para modelo grande...

[Conectando a LMStudio Link...]
Modelo: llama3.1:70b-q4

[Procesando con modelo grande...]
Análisis profundo completado.
Recomendaciones: ...

[Archivador: Guardado en memoria para futuras referencias]
```

---

## Mantenimiento Diario

### Verificación Matutina (2 min)

```bash
# Script en tu Mac Mini
~/openclaw/scripts/morning-check.sh
```

Output:
```
=== OPENCLAW Morning Check ===
✅ Gateway: Online (18789)
✅ Ollama: Online (3 models loaded)
✅ Redis: Online (1,247 keys)
✅ Mission Control: Online (18790)
✅ VPS: Reachable
⚠️  MacBook: Offline (esperado)

Memory: 4.2GB / 16GB (26%)
Disk: 234GB free / 4TB
Uptime: 15 days

All systems nominal ✓
```

### Backup Semanal

Automático cada domingo a las 3am.
Verificar en: `/Volumes/NVMe-4TB/openclaw/backups/`

---

## Límites y Consideraciones

### Lo que NO puede hacer

1. **Acceder a internet directamente** - Necesita que tú le proporciones contexto o active búsqueda
2. **Ejecutar código arbitrario** - Solo genera código, no lo ejecuta
3. **Modificar archivos del sistema** - Solo opera en su directorio `/openclaw/`
4. **Acceder a APIs externas sin tu permiso** - Solo las que configures

### Consideraciones de Privacidad

- Todas las conversaciones se guardan LOCALMENTE
- No hay envío de datos a terceros (salvo APIs cloud que configures)
- Puedes eliminar el historial en cualquier momento
- Los backups están en tu NVMe y VPS (bajo tu control)

---

**Documento:** Capacidades y Experiencia de Uso
**Ubicación:** `docs/INSTALACION-PERSONAL/06-capacidades-experiencia.md`
