# Master Index - OPENCLAW System

**Versión:** 2.1.0
**Schema:** `LLL-DDD-TTT-SSS-nombre_descriptivo`
**Actualizado:** 2026-03-09

---

## Formato de ID

```
LLL-DDD-TTT-SSS-nombre_descriptivo
│││ │││ │││ └─── SSS: Secuencia (001-999)
│││ │││ ││└──── TTT: Tipo (3 letras español, MAYÚSCULAS)
│││ │││ └────── DDD: Dominio (3 letras español, MAYÚSCULAS)
│││ └────────── LLL: Nivel (3 letras español, MAYÚSCULAS)
└────────────── nombre_descriptivo: Minúsculas con guiones bajos
```

### Ejemplo

```
ESP-DES-HER-001-herramientas
│││ │││ │││ │││  └── nombre: herramientas
│││ │││ │││ └──── secuencia: 001
│││ │││ ││└────── tipo: HER (herramientas)
│││ │││ └─────── dominio: DES (desarrollo)
│││ └────────── nivel: ESP (especialista)
```

---

## Códigos (TODO en español)

### Niveles (LLL)

| Código | Nombre | Descripción |
|--------|--------|-------------|
| SIS | Sistema | Nivel 0 - Configuración global, protocolos, plantillas |
| JEF | Jefatura | Nivel 1 - Jefes de dominio (Catedráticos) |
| ESP | Especialista | Nivel 2 - Unidades tri-agente |
| SUB | Subagente | Nivel 3 - Agentes temporales |

### Dominios (DDD)

| Código | Nombre | Nivel | Jefe | Namespace |
|--------|--------|-------|------|-----------|
| SMA | Sistema | SIS | - | - |
| BIB | Biblioteca | SIS | - | - |
| CON | Conocimiento | JEF | - | - |
| ING | Ingeniería | JEF | - | - |
| OPE | Operaciones | JEF | - | - |
| RHU | Recursos Humanos | JEF | - | - |
| REX | Relaciones Externas | JEF | - | - |
| COM | Comunicación | JEF | - | - |
| DES | Desarrollo | ESP | ING | /dev |
| INF | Infraestructura | ESP | ING | /infra |
| HOS | Hostelería | ESP | OPE | /hosteleria |
| ACA | Académico | ESP | CON | /academico |
| GEN | General | ESP | CON | /general |
| CRI | Criptomonedas | ESP | REX | /crypto |
| FIN | Finanzas | ESP | REX | /inversiones |
| DEP | Deportes | ESP | RHU | /fitness |
| IDI | Idiomas | ESP | COM | /english |

### Tipos (TTT)

| Código | Nombre | Extensión |
|--------|--------|-----------|
| CFG | Configuración | .yaml |
| UNI | Unidad | .yaml |
| DIR | Director | .yaml |
| EJE | Ejecutor | .yaml |
| ARC | Archivador | .yaml |
| CNO | Conocimiento | .md |
| MEM | Memoria | .db |
| HER | Herramientas | .yaml |
| PRO | Protocolo | .md |
| PLA | Plantilla | .yaml |
| REG | Registro | .yaml |

---

## Estructura de Directorios

```
OPENCLAW-system/
│
├── sistema/                          # Nivel SIS
│   └── configuracion/
│       └── SIS-SMA-CFG-001-sistema.yaml
│
├── biblioteca/                       # Nivel SIS
│   ├── protocolos/
│   │   ├── SIS-BIB-PRO-001-validacion.md
│   │   ├── SIS-BIB-PRO-002-evolucion.md
│   │   ├── SIS-BIB-PRO-003-recuperacion.md
│   │   ├── SIS-BIB-PRO-004-deprecacion.md
│   │   └── SIS-BIB-PRO-005-descubrimiento.md
│   │
│   ├── plantillas/
│   │   ├── SIS-BIB-PLA-001-especialista_base.yaml
│   │   └── SIS-BIB-PLA-002-triagente_estandar.yaml
│   │
│   └── registros/
│       ├── SIS-BIB-REG-001-habilidades.yaml
│       ├── SIS-BIB-REG-002-herramientas.yaml
│       └── SIS-BIB-REG-003-mapa_codigos.yaml
│
├── jefaturas/                        # Nivel JEF
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
├── especialistas/                    # Nivel ESP
│   ├── desarrollo/
│   │   ├── ESP-DES-UNI-001-desarrollo.yaml
│   │   └── herramientas/
│   │       └── ESP-DES-HER-001-herramientas.yaml
│   │
│   ├── infraestructura/
│   │   └── ESP-INF-UNI-001-infraestructura.yaml
│   │
│   ├── hosteleria/
│   │   └── ESP-HOS-UNI-001-hosteleria.yaml
│   │
│   ├── academico/
│   │   └── ESP-ACA-UNI-001-academico.yaml
│   │
│   ├── general/
│   │   └── ESP-GEN-UNI-001-general.yaml
│   │
│   ├── criptomonedas/
│   │   └── ESP-CRI-UNI-001-criptomonedas.yaml
│   │
│   ├── finanzas/
│   │   └── ESP-FIN-UNI-001-finanzas.yaml
│   │
│   ├── deportes/
│   │   └── ESP-DEP-UNI-001-deportes.yaml
│   │
│   └── idiomas/
│       └── ESP-IDI-UNI-001-idiomas.yaml
│
├── docs/                             # Documentación
├── config/                           # Configuración adicional
└── scripts/                          # Scripts de control
```

---

## Registro Completo

### Nivel SIS - Sistema (11 archivos)

| ID | Tipo | Nombre |
|----|------|--------|
| SIS-SMA-CFG-001-sistema | CFG | Sistema Config |
| SIS-BIB-PRO-001-validacion | PRO | Validación |
| SIS-BIB-PRO-002-evolucion | PRO | Evolución |
| SIS-BIB-PRO-003-recuperacion | PRO | Recuperación |
| SIS-BIB-PRO-004-deprecacion | PRO | Deprecación |
| SIS-BIB-PRO-005-descubrimiento | PRO | Descubrimiento |
| SIS-BIB-PLA-001-especialista_base | PLA | Especialista Base |
| SIS-BIB-PLA-002-triagente_estandar | PLA | Tri-Agente Estándar |
| SIS-BIB-REG-001-habilidades | REG | Habilidades |
| SIS-BIB-REG-002-herramientas | REG | Herramientas |
| SIS-BIB-REG-003-mapa_codigos | REG | Mapa de Códigos |

### Nivel JEF - Jefaturas (6 archivos)

| ID | Nombre | Dominios |
|----|--------|----------|
| JEF-CON-UNI-001-conocimiento | Conocimiento | ACA, GEN |
| JEF-ING-UNI-001-ingenieria | Ingeniería | DES, INF |
| JEF-OPE-UNI-001-operaciones | Operaciones | HOS |
| JEF-RHU-UNI-001-recursos_humanos | Recursos Humanos | DEP |
| JEF-REX-UNI-001-relaciones_externas | Relaciones Externas | CRI, FIN |
| JEF-COM-UNI-001-comunicacion | Comunicación | IDI |

### Nivel ESP - Especialistas (10 archivos)

| ID | Nombre | Jefe | Namespace |
|----|--------|------|-----------|
| ESP-DES-UNI-001-desarrollo | Desarrollo | ING | /dev |
| ESP-DES-HER-001-herramientas | H. Desarrollo | ING | - |
| ESP-INF-UNI-001-infraestructura | Infraestructura | ING | /infra |
| ESP-HOS-UNI-001-hosteleria | Hostelería | OPE | /hosteleria |
| ESP-ACA-UNI-001-academico | Académico | CON | /academico |
| ESP-GEN-UNI-001-general | General | CON | /general |
| ESP-CRI-UNI-001-criptomonedas | Criptomonedas | REX | /crypto |
| ESP-FIN-UNI-001-finanzas | Finanzas | REX | /inversiones |
| ESP-DEP-UNI-001-deportes | Deportes | RHU | /fitness |
| ESP-IDI-UNI-001-idiomas | Idiomas | COM | /english |

---

## Migración v2.0 → v2.1

| ID Anterior | ID Nuevo |
|-------------|----------|
| 0SYSC001 | SIS-SMA-CFG-001-sistema |
| 0LIBP001-005 | SIS-BIB-PRO-001-005 |
| 0LIBE001-002 | SIS-BIB-PLA-001-002 |
| 0LIBR001-002 | SIS-BIB-REG-001-002 |
| 1CKO001 | JEF-CON-UNI-001-conocimiento |
| 1CNG001 | JEF-ING-UNI-001-ingenieria |
| 1COO001 | JEF-OPE-UNI-001-operaciones |
| 1CHO001 | JEF-RHU-UNI-001-recursos_humanos |
| 1CSR001 | JEF-REX-UNI-001-relaciones_externas |
| 1CCO001 | JEF-COM-UNI-001-comunicacion |
| 2DEV001 | ESP-DES-UNI-001-desarrollo |
| 2INF001 | ESP-INF-UNI-001-infraestructura |
| 2HOS001 | ESP-HOS-UNI-001-hosteleria |
| 2ACA001 | ESP-ACA-UNI-001-academico |
| 2GEN001 | ESP-GEN-UNI-001-general |
| 2CRY001 | ESP-CRI-UNI-001-criptomonedas |
| 2FIN001 | ESP-FIN-UNI-001-finanzas |
| 2FIT001 | ESP-DEP-UNI-001-deportes |
| 2LAN001 | ESP-IDI-UNI-001-idiomas |

---

**Documento:** Master Index
**Ubicación:** `/INDEX.md`
**Versión:** 2.1.0
