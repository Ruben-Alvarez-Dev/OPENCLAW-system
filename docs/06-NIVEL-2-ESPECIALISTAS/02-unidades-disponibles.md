# Unidades Especialistas Disponibles

**ID:** DOC-ESP-UNI-001
**Nivel:** ESP - Especialistas
**Versión:** 2.1.0
**Fecha:** 2026-03-09

---

## Resumen

Las unidades especialistas son los equipos de trabajo de OPENCLAW. Cada unidad sigue el patrón tri-agente y está optimizada para un dominio específico.

---

## Índice de Unidades

| ID | Unidad | Namespace | Jefe | Estado |
|----|--------|-----------|------|--------|
| [ESP-DES-UNI-001](#esp-des-uni-001---desarrollo) | Desarrollo | `/dev` | JEF-ING | ✅ Activo |
| [ESP-INF-UNI-001](#esp-inf-uni-001---infraestructura) | Infraestructura | `/infra` | JEF-ING | ✅ Activo |
| [ESP-HOS-UNI-001](#esp-hos-uni-001---hosteleria) | Hostelería | `/hosteleria` | JEF-OPE | ✅ Activo |
| [ESP-ACA-UNI-001](#esp-aca-uni-001---academico) | Académico | `/academico` | JEF-CON | ✅ Activo |
| [ESP-GEN-UNI-001](#esp-gen-uni-001---general) | General | `/general` | JEF-CON | ✅ Activo |
| [ESP-CRI-UNI-001](#esp-cri-uni-001---criptomonedas) | Criptomonedas | `/crypto` | JEF-REX | ✅ Activo |
| [ESP-DEP-UNI-001](#esp-dep-uni-001---deportes) | Deportes | `/fitness` | JEF-RHU | ✅ Activo |
| [ESP-FIN-UNI-001](#esp-fin-uni-001---finanzas) | Finanzas | `/inversiones` | JEF-REX | ✅ Activo |
| [ESP-IDI-UNI-001](#esp-idi-uni-001---idiomas) | Idiomas | `/english` | JEF-COM | ✅ Activo |

---

## ESP-DES-UNI-001 - Desarrollo

### Información General

| Campo | Valor |
|-------|-------|
| **ID** | `ESP-DES-UNI-001-desarrollo` |
| **Namespace** | `/dev` |
| **Jefe** | JEF-ING (Jefe de Ingeniería) |
| **Propósito** | Desarrollo de software, arquitectura, calidad de código |

### Sub-unidades

| Sub-unidad | Función |
|------------|---------|
| DES-Core | Desarrollo principal, código |
| DES-Infra | Despliegue, configuración de entornos |
| DES-QA | Testing, calidad, validación |

### Habilidades Principales

- **Lenguajes:** TypeScript, Python, Rust, Go, Java, JavaScript
- **Frameworks:** React, Vue, Node.js, Django, FastAPI, Spring Boot
- **Bases de datos:** PostgreSQL, MongoDB, Redis, Elasticsearch
- **DevOps:** Docker, Kubernetes, GitHub Actions, Terraform

### Ejemplos de Uso

```
/dev crear API REST con Express para gestión de usuarios
/dev refactorizar src/auth.ts para usar patrón Repository
/dev añadir tests unitarios para src/services/user.service.ts
/dev revisar PR #123 y sugerir mejoras
```

### Perfil Completo

Ver: [`especialistas/desarrollo/ESP-DES-UNI-001-desarrollo.yaml`](../../especialistas/desarrollo/ESP-DES-UNI-001-desarrollo.yaml)

---

## ESP-INF-UNI-001 - Infraestructura

### Información General

| Campo | Valor |
|-------|-------|
| **ID** | `ESP-INF-UNI-001-infraestructura` |
| **Namespace** | `/infra` |
| **Jefe** | JEF-ING (Jefe de Ingeniería) |
| **Propósito** | Infraestructura, DevOps, servidores, networking |

### Sub-unidades

| Sub-unidad | Función |
|------------|---------|
| INF-Servidores | Provisioning, configuración de servidores |
| INF-Red | Firewalls, VPNs, load balancers |
| INF-DevOps | CI/CD, automatización |
| INF-Monitoreo | Prometheus, Grafana, alertas |

### Habilidades Principales

- **Cloud:** AWS, GCP, Azure, DigitalOcean, Hetzner
- **Sistemas:** Ubuntu, Debian, CentOS, Alpine
- **IaC:** Terraform, Ansible, Puppet
- **Containers:** Docker, Kubernetes, Podman
- **Monitoreo:** Prometheus, Grafana, Loki, ELK

### Políticas Especiales

- `requiere_aprobacion: true` - Todos los cambios de infra requieren approval
- `requiere_backup: true` - Backup obligatorio antes de cambios
- `auditar_todos_comandos: true` - Auditoría completa de comandos

### Ejemplos de Uso

```
/infra configurar VPS Ubuntu con Docker, Nginx y SSL
/infra diseñar arquitectura de alta disponibilidad para web app
/infra crear pipeline CI/CD con GitHub Actions para Kubernetes
/infra setup monitoring con Prometheus y Grafana
```

### Perfil Completo

Ver: [`especialistas/infraestructura/ESP-INF-UNI-001-infraestructura.yaml`](../../especialistas/infraestructura/ESP-INF-UNI-001-infraestructura.yaml)

---

## ESP-HOS-UNI-001 - Hostelería

### Información General

| Campo | Valor |
|-------|-------|
| **ID** | `ESP-HOS-UNI-001-hosteleria` |
| **Namespace** | `/hosteleria` |
| **Aliases** | `/fnb`, `/f&b`, `/gastronomia` |
| **Jefe** | JEF-OPE (Jefe de Operaciones) |
| **Propósito** | Gastronomía, restauración, F&B, eventos |

### Sub-unidades

| Sub-unidad | Función |
|------------|---------|
| HOS-Cocina | Recetas, técnicas, escandallos |
| HOS-Operaciones | Procedimientos, checklists |
| HOS-Bebidas | Vinos, coctelería, maridajes |
| HOS-Eventos | Catering, planificación |

### Habilidades Principales

- **Cocinas:** Mediterránea, Asiática, Francesa, Vegetariana
- **Bebidas:** Sommelier, Coctelería, Barismo
- **Gestión:** Food Cost, Alérgenos, HACCP
- **Normativa:** Seguridad alimentaria, Licencias

### Políticas Especiales

- `identificar_alergenos: true` - Siempre identificar alérgenos
- `calcular_costo: true` - Escandallo obligatorio

### Ejemplos de Uso

```
/hosteleria diseñar carta para restaurante italiano de 60 plazas
/hosteleria crear ficha técnica de risotto de boletus con escandallo
/hosteleria planificar menú para boda de 150 personas
/hosteleria sugerir maridaje de vinos para menú japonés
```

### Perfil Completo

Ver: [`especialistas/hosteleria/ESP-HOS-UNI-001-hosteleria.yaml`](../../especialistas/hosteleria/ESP-HOS-UNI-001-hosteleria.yaml)

---

## ESP-ACA-UNI-001 - Académico

### Información General

| Campo | Valor |
|-------|-------|
| **ID** | `ESP-ACA-UNI-001-academico` |
| **Namespace** | `/academico` |
| **Aliases** | `/oposiciones`, `/estudio`, `/tutor` |
| **Jefe** | JEF-CON (Jefe de Conocimiento) |
| **Propósito** | Educación, oposiciones, preparación de exámenes |

### Sub-unidades

| Sub-unidad | Función |
|------------|---------|
| ACA-Investigacion | Investigación académica, papers |
| ACA-Tutoria | Tutoría, explicación de conceptos |
| ACA-Preparacion | Preparación de exámenes, tests |

### Habilidades Principales

- **Asignaturas:** Matemáticas, Física, Química, Historia, Derecho, Economía
- **Oposiciones:** Administrativas, Judiciales, Docentes, Sanitarias, Fuerzas
- **Exámenes:** IELTS, TOEFL, Cambridge, DELE

### Políticas Especiales

- `citar_fuentes: true` - Citar fuentes siempre
- `verificar_hechos: true` - Verificar hechos
- `nivel_adaptativo: true` - Adaptar nivel al estudiante

### Ejemplos de Uso

```
/academico explicar derivadas para estudiante de bachillerato
/academico preparar tema de derecho administrativo para AEAT
/academico generar test de 20 preguntas sobre la Constitución
/academico resolver integrales paso a paso
```

### Perfil Completo

Ver: [`especialistas/academico/ESP-ACA-UNI-001-academico.yaml`](../../especialistas/academico/ESP-ACA-UNI-001-academico.yaml)

---

## ESP-GEN-UNI-001 - General

### Información General

| Campo | Valor |
|-------|-------|
| **ID** | `ESP-GEN-UNI-001-general` |
| **Namespace** | `/general` |
| **Aliases** | `/default`, `/ayuda` |
| **Jefe** | JEF-CON (Jefe de Conocimiento) |
| **Propósito** | Propósito general, fallback, routing |

### Función Especial

GENERAL es la unidad de fallback que:
1. Clasifica la intención del usuario
2. Resuelve consultas generales
3. Sugiere el dominio especializado apropiado
4. Enruta a la unidad correcta

### Comportamiento de Routing

```
if contiene_terminos_codigo(query):     → /dev
elif contiene_terminos_infra(query):    → /infra
elif contiene_terminos_comida(query):   → /hosteleria
elif contiene_terminos_academico(query): → /academico
elif contiene_terminos_crypto(query):   → /crypto
elif contiene_terminos_finanzas(query): → /inversiones
elif contiene_terminos_fitness(query):  → /fitness
elif contiene_terminos_idiomas(query):  → /english
else:                                   → /general
```

### Ejemplos de Uso

```
/general ¿Cuál es la capital de Australia?
/general redactar email formal solicitando reunión
/general resumir este artículo en 3 puntos clave
/general ¿Cómo configuro un servidor?  → Sugerirá /infra
```

### Perfil Completo

Ver: [`especialistas/general/ESP-GEN-UNI-001-general.yaml`](../../especialistas/general/ESP-GEN-UNI-001-general.yaml)

---

## ESP-CRI-UNI-001 - Criptomonedas

### Información General

| Campo | Valor |
|-------|-------|
| **ID** | `ESP-CRI-UNI-001-criptomonedas` |
| **Namespace** | `/crypto` |
| **Jefe** | JEF-REX (Jefe de Relaciones Externas) |
| **Propósito** | Criptomonedas, blockchain, DeFi, análisis crypto |

### Sub-unidades

| Sub-unidad | Función |
|------------|---------|
| CRI-Analisis | Análisis técnico, fundamental, on-chain |
| CRI-DeFi | Evaluación de protocolos, yields |
| CRI-Trading | Señales, análisis de mercado |

### Habilidades Principales

- **Blockchains:** Bitcoin, Ethereum, Solana, Polygon, Arbitrum
- **DeFi:** DEXs, Lending, Yield Farming, Liquid Staking
- **Análisis:** Técnico, Fundamental, On-chain, Sentimiento

### Aviso Obligatorio

> "Esto NO es asesoramiento financiero. Siempre DYOR (Do Your Own Research). Los mercados crypto son altamente volátiles."

### Ejemplos de Uso

```
/crypto analizar BTC/USDT en timeframe diario
/crypto explicar qué es Uniswap y cómo funciona
/crypto evaluar riesgo de prestar en Aave
/crypto analizar sentimiento del mercado hoy
```

### Perfil Completo

Ver: [`especialistas/criptomonedas/ESP-CRI-UNI-001-criptomonedas.yaml`](../../especialistas/criptomonedas/ESP-CRI-UNI-001-criptomonedas.yaml)

---

## ESP-DEP-UNI-001 - Deportes

### Información General

| Campo | Valor |
|-------|-------|
| **ID** | `ESP-DEP-UNI-001-deportes` |
| **Namespace** | `/fitness` |
| **Jefe** | JEF-RHU (Jefe de Recursos Humanos) |
| **Propósito** | Entrenamiento, nutrición deportiva, bienestar |

### Sub-unidades

| Sub-unidad | Función |
|------------|---------|
| DEP-Entrenamiento | Planes de entrenamiento |
| DEP-Nutricion | Macros, planes alimenticios |
| DEP-Recuperacion | Recuperación, prevención lesiones |

### Habilidades Principales

- **Entrenamiento:** Fuerza, Cardio, HIIT, Calistenia, Powerlifting
- **Nutrición:** Macros, Planificación de comidas, Suplementos
- **Objetivos:** Pérdida peso, Ganancia muscular, Resistencia

### Aviso de Seguridad

> "Consultar siempre con un profesional de la salud antes de iniciar programas intensivos."

### Ejemplos de Uso

```
/fitness crear plan de fuerza 4 días/semana para principiante
/fitness calcular macros para ganar masa muscular (80kg, 180cm)
/fitness plan de nutrición para maratón de 3 meses
/fitness explicar técnica correcta de sentadilla
```

### Perfil Completo

Ver: [`especialistas/deportes/ESP-DEP-UNI-001-deportes.yaml`](../../especialistas/deportes/ESP-DEP-UNI-001-deportes.yaml)

---

## ESP-FIN-UNI-001 - Finanzas

### Información General

| Campo | Valor |
|-------|-------|
| **ID** | `ESP-FIN-UNI-001-finanzas` |
| **Namespace** | `/inversiones` |
| **Aliases** | `/finanzas`, `/inversion` |
| **Jefe** | JEF-REX (Jefe de Relaciones Externas) |
| **Propósito** | Inversiones tradicionales, finanzas personales |

### Sub-unidades

| Sub-unidad | Función |
|------------|---------|
| FIN-Planificacion | Planes financieros, jubilación |
| FIN-Inversion | Análisis de activos, carteras |
| FIN-Analisis | Análisis fundamental, técnico |

### Habilidades Principales

- **Mercados:** Acciones, Bonos, ETFs, REITs, Commodities
- **Personal:** Presupuestos, Ahorro, Jubilación, Fiscal
- **Análisis:** Fundamental, Técnico, Teoría de Carteras

### Aviso Obligatorio

> "NO constituye asesoramiento financiero profesional. Consultar siempre con un asesor financiero certificado."

### Ejemplos de Uso

```
/inversiones analizar acción AAPL con análisis fundamental
/inversiones crear cartera diversificada para perfil moderado
/inversiones plan de ahorro para jubilación (30 años, 1000€/mes)
/inversiones explicar diferencias entre ETF y fondo indexado
```

### Perfil Completo

Ver: [`especialistas/finanzas/ESP-FIN-UNI-001-finanzas.yaml`](../../especialistas/finanzas/ESP-FIN-UNI-001-finanzas.yaml)

---

## ESP-IDI-UNI-001 - Idiomas

### Información General

| Campo | Valor |
|-------|-------|
| **ID** | `ESP-IDI-UNI-001-idiomas` |
| **Namespace** | `/english` |
| **Aliases** | `/idiomas`, `/spanish`, `/french` |
| **Jefe** | JEF-COM (Jefe de Comunicación) |
| **Propósito** | Aprendizaje de idiomas, conversación, exámenes |

### Sub-unidades

| Sub-unidad | Función |
|------------|---------|
| IDI-Conversacion | Práctica de conversación |
| IDI-Gramatica | Explicación gramática |
| IDI-Preparacion | Preparación IELTS, TOEFL, Cambridge |

### Habilidades Principales

- **Idiomas:** Inglés, Español, Francés, Alemán, Portugués, Italiano
- **Exámenes:** IELTS, TOEFL, Cambridge, DELE, DELF
- **Áreas:** Business English, Academic Writing, Pronunciación

### Ejemplos de Uso

```
/english practicar conversación para entrevista de trabajo
/english corregir este texto: "Yesterday I go to the store"
/english preparar IELTS Academic, objetivo band 7
/english enseñar 20 expresiones idiomáticas de negocios
/english explicar diferencia entre present perfect y past simple
```

### Perfil Completo

Ver: [`especialistas/idiomas/ESP-IDI-UNI-001-idiomas.yaml`](../../especialistas/idiomas/ESP-IDI-UNI-001-idiomas.yaml)

---

## Estadísticas

| Métrica | Valor |
|---------|-------|
| Total unidades activas | 9 |
| Unidades por JEF-ING | 2 |
| Unidades por JEF-CON | 2 |
| Unidades por JEF-REX | 2 |
| Unidades por JEF-OPE | 1 |
| Unidades por JEF-RHU | 1 |
| Unidades por JEF-COM | 1 |

---

## Referencias

- [00-overview.md](./00-overview.md) - Visión general de Nivel ESP
- [01-patron-triunvirato.md](./01-patron-triunvirato.md) - Patrón Tri-Agente
- [03-agent-factory.md](./03-agent-factory.md) - Fábrica de Agentes
- [../05-NIVEL-1-CATEDRATICOS/00-overview.md](../05-NIVEL-1-CATEDRATICOS/00-overview.md) - Catedráticos
- [INDEX.md](../../INDEX.md) - Índice principal

---

**Documento:** Unidades Especialistas Disponibles
**Ubicación:** `docs/06-NIVEL-2-ESPECIALISTAS/02-unidades-disponibles.md`
**Versión:** 2.1.0
**Fecha:** 2026-03-09
