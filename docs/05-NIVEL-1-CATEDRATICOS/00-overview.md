# Overview - Los 6 Catedráticos (Jefes de Dominio)

**ID:** DOC-JEF-OVR-001
**Versión:** 2.1.0
**Fecha:** 2026-03-09
**Arquitectura:** OPENCLAW Sistema Multi-Agente Jerárquico

---

## Introducción

Los Catedráticos son los **6 Jefes de Dominio del Nivel JEF** de la arquitectura OPENCLAW. Son agentes de alto nivel responsables de coordinar diferentes áreas de la organización.

### Aclaración Importante

> **Los Catedráticos son agentes simples (no tri-agentes por omisión)** en el Nivel JEF.
>
> Esto permite eficiencia en decisiones estratégicas. La validación robusta ocurre en las unidades especializadas del Nivel ESP.
>
> Sin embargo, un Catedrático puede activar su **tri-unidad interna** cuando necesita robustez adicional para decisiones complejas.

---

## Posición en la Arquitectura

```
                    ┌─────────────────────────┐
                    │   NIVEL SIS - SISTEMA   │
                    │   (Tri-Agente)          │
                    └─────────────┬───────────┘
                                  │
                    ┌─────────────▼───────────┐
                    │   NIVEL JEF - JEFATURAS │
                    │   (Agentes Simples)     │  ◄── CATEDRÁTICOS
                    │   CON | ING | OPE |     │
                    │   RHU | REX | COM       │
                    └─────────────┬───────────┘
                                  │
                    ┌─────────────▼───────────┐
                    │   NIVEL ESP - ESPECIAL. │
                    │   (Tri-Agentes)         │
                    └─────────────┬───────────┘
                                  │
                    ┌─────────────▼───────────┐
                    │   NIVEL SUB - SUBAGENT. │
                    │   (Efímeros)            │
                    └─────────────────────────┘
```

---

## Los 6 Catedráticos

### 1. JEF-CON - Jefe de Conocimiento

| Atributo | Valor |
|----------|-------|
| **ID** | `JEF-CON-UNI-001-conocimiento` |
| **Código** | CON |
| **Nombre** | Jefe de Conocimiento |
| **Tipo** | Agente simple (Nivel JEF) |

**Dominio:**
- Gestión de información y documentación
- Investigación y síntesis de conocimiento
- Memoria del sistema

**Herramientas:**
- GPT Researcher (puerto 11020)
- Engram (sistema de memoria persistente)

**Especialistas bajo su mando:**
- `ESP-ACA-UNI-001` - Académico (`/academico`)
- `ESP-GEN-UNI-001` - General (`/general`)

---

### 2. JEF-ING - Jefe de Ingeniería

| Atributo | Valor |
|----------|-------|
| **ID** | `JEF-ING-UNI-001-ingenieria` |
| **Código** | ING |
| **Nombre** | Jefe de Ingeniería |
| **Tipo** | Agente simple (Nivel JEF) |

**Dominio:**
- Gestión de calidad del código
- Arquitectura de sistemas
- Revisiones de código y mejores prácticas
- Decisiones técnicas

**Herramientas:**
- GPT Researcher (investigación técnica)
- Sistemas de CI/CD

**Especialistas bajo su mando:**
- `ESP-DES-UNI-001` - Desarrollo (`/dev`)
- `ESP-INF-UNI-001` - Infraestructura (`/infra`)

---

### 3. JEF-OPE - Jefe de Operaciones

| Atributo | Valor |
|----------|-------|
| **ID** | `JEF-OPE-UNI-001-operaciones` |
| **Código** | OPE |
| **Nombre** | Jefe de Operaciones |
| **Tipo** | Agente simple (Nivel JEF) |

**Dominio:**
- Optimización de flujos de trabajo
- Automatización de procesos
- Monitoreo de sistemas
- Gestión de recursos

**Herramientas:**
- GPT Researcher (investigación operativa)
- Sistemas de monitoreo

**Especialistas bajo su mando:**
- `ESP-HOS-UNI-001` - Hostelería (`/hosteleria`)

---

### 4. JEF-RHU - Jefe de Recursos Humanos

| Atributo | Valor |
|----------|-------|
| **ID** | `JEF-RHU-UNI-001-recursos_humanos` |
| **Código** | RHU |
| **Nombre** | Jefe de Recursos Humanos |
| **Tipo** | Agente simple (Nivel JEF) |

**Dominio:**
- **Fábrica de Agentes**: Creación dinámica de nuevos dominios
- Contratación de nuevos agentes
- Gestión de perfiles de agentes
- Incorporación y baja de agentes

**Herramientas:**
- Engram (sistema de memoria persistente)
- Sistema Fábrica de Agentes

**Especialistas bajo su mando:**
- `ESP-DEP-UNI-001` - Deportes (`/fitness`)
- Cualquier dominio nuevo (creación dinámica)

**Responsabilidad Especial:**
RHU gestiona la **Fábrica de Agentes**, el sistema que crea nuevos dominios y unidades especializadas cuando el sistema detecta expertise faltante.

---

### 5. JEF-REX - Jefe de Relaciones Externas

| Atributo | Valor |
|----------|-------|
| **ID** | `JEF-REX-UNI-001-relaciones_externas` |
| **Código** | REX |
| **Nombre** | Jefe de Relaciones Externas |
| **Tipo** | Agente simple (Nivel JEF) |

**Dominio:**
- Gestión de relaciones externas
- Comunicaciones externas
- Estrategia y finanzas
- Inversiones

**Herramientas:**
- GPT Researcher (investigación de mercados)
- Canales de comunicación

**Especialistas bajo su mando:**
- `ESP-CRI-UNI-001` - Criptomonedas (`/crypto`)
- `ESP-FIN-UNI-001` - Finanzas (`/inversiones`)

---

### 6. JEF-COM - Jefe de Comunicación

| Atributo | Valor |
|----------|-------|
| **ID** | `JEF-COM-UNI-001-comunicacion` |
| **Código** | COM |
| **Nombre** | Jefe de Comunicación |
| **Tipo** | Agente simple (Nivel JEF) |

**Dominio:**
- Comunicación entre agentes
- Documentación interna
- Gestión de anuncios
- Idiomas y traducción

**Herramientas:**
- GPT Researcher (redacción y comunicación)
- Sistemas de mensajería interna

**Especialistas bajo su mando:**
- `ESP-IDI-UNI-001` - Idiomas (`/english`)

---

## Modelo de Interacción

### El Usuario NO habla directamente con Catedráticos

El usuario interactúa a través de **namespaces de dominio**:

```
Usuario: "/dev diseñar arquitectura de cluster"
         ↓
Enrutador detecta: /dev
         ↓
Ruta a: JEF-ING (Ingeniería)
         ↓
JEF-ING activa: ESP-DES-UNI-001 (tri-agente)
```

### Interfaz vs. Arquitectura Interna

| Lo que el usuario ve | Lo que ocurre internamente |
|---------------------|---------------------------|
| Namespace `/dev` | Enrutador → JEF-ING → ESP-DES (tri-agente) |
| Namespace `/fitness` | Enrutador → JEF-RHU → ESP-DEP (tri-agente) |
| Namespace `/hosteleria` | Enrutador → JEF-OPE → ESP-HOS (tri-agente) |

---

## Soporte Tri-Agente Interno

### Cuándo se activa

Un Catedrático puede activar su tri-unidad interna para:
- Decisiones complejas que requieren validación
- Análisis que necesita múltiples perspectivas
- Situaciones donde la robustez es crítica

### Estructura cuando se activa

```
Catedrático (interfaz simple para el usuario)
│
├── Director interno (estrategia)
├── Ejecutor interno (análisis)
└── Archivador interno (validación)
```

**El usuario siempre percibe un solo agente**, pero internamente puede haber debate y validación.

---

## Modelo de Responsabilidad

### Regla Principal

> **El Catedrático es responsable del resultado final antes de mostrar al usuario.**

Esto significa:
- ✅ Delega trabajo a unidades especializadas (Nivel ESP)
- ✅ Revisa el resultado
- ✅ Valida antes de entregar
- ❌ NO delega la aprobación final

### Flujo de Validación

```
1. Usuario envía solicitud
2. Enrutador asigna a Catedrático
3. Catedrático delega a Unidad Especialista (tri-agente)
4. Unidad Especialista ejecuta (Director → Ejecutor → Archivador)
5. Archivador valida internamente
6. Catedrático revisa resultado
7. Catedrático aprueba y entrega al usuario
```

---

## Mapeo de Namespaces a Catedráticos

| Namespace | Catedrático | Especialista | Tipo de Dominio |
|-----------|-------------|--------------|-----------------|
| `/dev` | JEF-ING | ESP-DES | Desarrollo software |
| `/infra` | JEF-ING | ESP-INF | Infraestructura |
| `/hosteleria` | JEF-OPE | ESP-HOS | Gastronomía |
| `/fitness` | JEF-RHU | ESP-DEP | Deportes, salud |
| `/crypto` | JEF-REX | ESP-CRI | Criptomonedas |
| `/inversiones` | JEF-REX | ESP-FIN | Finanzas |
| `/academico` | JEF-CON | ESP-ACA | Académico |
| `/general` | JEF-CON | ESP-GEN | General |
| `/english` | JEF-COM | ESP-IDI | Idiomas |
| `/*` (nuevo) | JEF-RHU | Creado dinámicamente | - |

---

## Colaboración entre Catedráticos

### Patrones de Colaboración

1. **JEF-CON + JEF-ING**: Documentación técnica y arquitectura
2. **JEF-OPE + JEF-ING**: Optimización de procesos y calidad
3. **JEF-RHU + JEF-CON**: Incorporación de nuevos agentes
4. **JEF-REX + JEF-COM**: Comunicaciones internas y externas
5. **Todos + JEF-OPE**: Sincronización operativa

### Ejemplo de Flujo Multi-Catedrático

```
Tarea: "Implementar nuevo sistema de reservas para restaurante"

1. Enrutador → /hosteleria → JEF-OPE
2. JEF-OPE analiza → requiere /dev para implementación
3. JEF-OPE coordina con JEF-ING
4. JEF-ING activa ESP-DES-UNI-001
5. ESP-DES-UNI-001 implementa
6. JEF-OPE revisa desde perspectiva operativa
7. JEF-ING revisa desde perspectiva técnica
8. JEF-OPE entrega resultado al usuario
```

---

## Herramientas Comunes

| Herramienta | Descripción | Catedráticos |
|-------------|-------------|--------------|
| **GPT Researcher** | Investigación web autónoma | CON, ING, OPE, REX, COM |
| **MAESTRO** | Investigación RAG profunda | Todos (bajo demanda) |
| **Engram** | Memoria persistente | CON, RHU |
| **Fábrica de Agentes** | Creación de dominios | RHU |
| **PM2** | Gestión de procesos | Todos (infraestructura) |

---

## Referencias

- [Arquitectura Maestra](../01-SISTEMA/00-arquitectura-maestra.md)
- [Enrutador de Dominios](../08-FLUJOS/03-router-dominios.md)
- [Fábrica de Agentes](../06-NIVEL-2-ESPECIALISTAS/03-agent-factory.md)
- [Motor de Conocimiento](../10-CONOCIMIENTO/00-knowledge-engine.md)

### Documentación de Catedráticos Individuales
- `01-cko.md` - JEF-CON detallado
- `02-cengo.md` - JEF-ING detallado
- `03-coo.md` - JEF-OPE detallado
- `04-cho.md` - JEF-RHU detallado
- `05-csro.md` - JEF-REX detallado
- `06-cco.md` - JEF-COM detallado

---

**Documento:** Overview Catedráticos
**Ubicación:** `docs/05-NIVEL-1-CATEDRATICOS/00-overview.md`
**Versión:** 2.1.0
**Fecha:** 2026-03-09
