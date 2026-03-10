# OPENCLAW - Sistema Multi-Agente Jerárquico

**Fecha:** 2026-03-10
**Versión:** 3.0.0
**Estado:** Documentación Lista para Producción
**Repositorio:** https://github.com/openclaw/openclaw

**Sitio web:** https://openclaw.ai
**Documentación:** [./docs/00-INDICE.md](./docs/00-INDICE.md)

---

## Resumen

OPENCLAW es un sistema multi-agente jerárquico diseñado para emular organizaciones humanas estructuradas. Combina orquestación, especialización por dominio y unidades tri-agente para producir salidas estables y verificables.

**Framework Base:** OpenClaw v2026.3.8 (20+ canales, 30+ proveedores IA)

---

## Arquitectura: Mezcla de Expertos (MoE)

### Nivel SIS - Orquestador
- Punto de entrada y coordinación global
- Enrutamiento de dominios
- Seguridad y políticas del sistema
- Fábrica de Agentes (creación dinámica)

### Nivel JEF - Los Seis Catedráticos

| Jefe | ID | Responsabilidad | Herramientas Clave |
|------|-----|----------------|---------------------|
| **Conocimiento** | `JEF-CON-UNI-001` | Gestión de conocimiento | GPT Researcher, Engram |
| **Ingeniería** | `JEF-ING-UNI-001` | Ingeniería, calidad, arquitectura | GPT Researcher |
| **Operaciones** | `JEF-OPE-UNI-001` | Operaciones, procesos | GPT Researcher |
| **Recursos Humanos** | `JEF-RHU-UNI-001` | RRHH, talento, fábrica | Engram |
| **Relaciones Externas** | `JEF-REX-UNI-001` | Relaciones externas | GPT Researcher |
| **Comunicación** | `JEF-COM-UNI-001` | Comunicaciones | GPT Researcher |

### Nivel ESP - Especialistas (Latentes)
- Agentes especializados en dominios específicos
- Heredan conocimiento de los Catedráticos
- Estructura tri-agente (Director, Ejecutor, Archivador)
- Invocados bajo demanda

### Nivel SUB - Subagentes (Efímeros)
- Trabajadores temporales para tareas específicas
- Vida corta
- Terminan al completar tarea
- Reportan resultados a Catedráticos

---

## Estructura de Directorios

```
OPENCLAW-system/
│
├── sistema/                    # Nivel SIS - Configuración
│   └── configuracion/
│       └── SIS-SMA-CFG-001-sistema.yaml
│
├── biblioteca/                 # Nivel SIS - Recursos compartidos
│   ├── protocolos/
│   │   ├── SIS-BIB-PRO-001-validacion.md
│   │   ├── SIS-BIB-PRO-002-evolucion.md
│   │   ├── SIS-BIB-PRO-003-recuperacion.md
│   │   ├── SIS-BIB-PRO-004-deprecacion.md
│   │   └── SIS-BIB-PRO-005-descubrimiento.md
│   ├── plantillas/
│   │   ├── SIS-BIB-PLA-001-especialista_base.yaml
│   │   └── SIS-BIB-PLA-002-triagente_estandar.yaml
│   └── registros/
│       ├── SIS-BIB-REG-001-habilidades.yaml
│       ├── SIS-BIB-REG-002-herramientas.yaml
│       └── SIS-BIB-REG-003-mapa_codigos.yaml
│
├── jefaturas/                  # Nivel JEF - Jefes de dominio
│   ├── conocimiento/
│   │   └── JEF-CON-UNI-001-conocimiento.yaml
│   ├── ingenieria/
│   │   └── JEF-ING-UNI-001-ingenieria.yaml
│   ├── operaciones/
│   │   └── JEF-OPE-UNI-001-operaciones.yaml
│   ├── recursos_humanos/
│   │   └── JEF-RHU-UNI-001-recursos_humanos.yaml
│   ├── relaciones_externas/
│   │   └── JEF-REX-UNI-001-relaciones_externas.yaml
│   └── comunicacion/
│       └── JEF-COM-UNI-001-comunicacion.yaml
│
├── especialistas/              # Nivel ESP - Unidades especializadas
│   ├── desarrollo/
│   │   └── ESP-DES-UNI-001-desarrollo.yaml
│   ├── infraestructura/
│   │   └── ESP-INF-UNI-001-infraestructura.yaml
│   ├── hosteleria/
│   │   └── ESP-HOS-UNI-001-hosteleria.yaml
│   ├── academico/
│   │   └── ESP-ACA-UNI-001-academico.yaml
│   ├── general/
│   │   └── ESP-GEN-UNI-001-general.yaml
│   ├── criptomonedas/
│   │   └── ESP-CRI-UNI-001-criptomonedas.yaml
│   ├── finanzas/
│   │   └── ESP-FIN-UNI-001-finanzas.yaml
│   ├── deportes/
│   │   └── ESP-DEP-UNI-001-deportes.yaml
│   └── idiomas/
│       └── ESP-IDI-UNI-001-idiomas.yaml
│
├── docs/                       # Documentación
├── config/                     # Configuración adicional
└── scripts/                    # Scripts de control
```

---

## Formato de ID

```
LLL-DDD-TTT-SSS-nombre_descriptivo
│││ │││ │││ └─── SSS: Secuencia (001-999)
│││ │││ ││└──── TTT: Tipo (3 letras español, MAYÚSCULAS)
│││ │││ └────── DDD: Dominio (3 letras español, MAYÚSCULAS)
│││ └────────── LLL: Nivel (3 letters español, MAYÚSCULAS)
└────────────── nombre_descriptivo: Minúsculas con guiones bajos
```

### Ejemplo

```
ESP-DES-HER-001-herramientas
│││ │││ │││ │││  └── nombre: herramientas
│││ │││ │││ └──── secuencia: 001
│││ │││ ││└────── tipo: HER (herramientas)
│││ │││ └─────── dominio: DES (desarrollo)
│││ └─────────── nivel: ESP (especialista)
```

---

## Namespaces de Usuario

| Namespace | Dominio | Descripción |
|-----------|---------|-------------|
| `/dev` | DES | Desarrollo, código, arquitectura |
| `/infra` | INF | Infraestructura, DevOps, servidores |
| `/hosteleria` | HOS | Hostelería, gastronomía |
| `/academico` | ACA | Oposiciones, estudio |
| `/general` | GEN | Consultas generales |
| `/crypto` | CRI | Criptomonedas, blockchain |
| `/inversiones` | FIN | Inversiones, finanzas |
| `/fitness` | DEP | Deportes, entrenamiento |
| `/english` | IDI | Aprendizaje de idiomas |

---

## Comandos Principales

### Control de Herramientas

```bash
./scripts/tools-control.sh gpt-researcher start|stop|status|logs
./scripts/tools-control.sh maestro start|stop|status|logs
./scripts/tools-control.sh engram stats|search|save|context
./scripts/tools-control.sh status  # Verificar todas las herramientas
```

### Endpoints

| Herramienta | Puerto | Uso |
|-------------|--------|-----|
| GPT Researcher | 11020 | Investigación web rápida |
| MAESTRO | 80 | Investigación profunda multi-agente |
| Engram | MCP | Memoria persistente |

---

## Inicio Rápido

1. **Configuración:** Editar `sistema/configuracion/SIS-SMA-CFG-001-sistema.yaml`
2. **Añadir conocimiento:** Colocar documentos en `especialistas/{dominio}/conocimiento/`
3. **Iniciar herramientas:** `./scripts/tools-control.sh status`
4. **Consultar:** Usar namespace apropiado (ej: `/dev ayuda con el código`)

---

## Documentación

| Documento | Ruta |
|-----------|------|
| Índice principal | `INDEX.md` |
| Guía Claude | `CLAUDE.md` |
| Protocolos | `biblioteca/protocolos/` |
| Plantillas | `biblioteca/plantillas/` |

---

**Licencia:** MIT
**Autor:** OPENCLAW Team
