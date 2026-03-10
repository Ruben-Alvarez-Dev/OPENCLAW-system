# Nivel ESP - Unidades Especialistas

**ID:** DOC-ESP-OVR-001
**Versión:** 2.1.0
**Fecha:** 2026-03-09
**Tipo:** Unidades Tri-Agente
**Función:** Ejecución especializada con validación interna

---

## Concepto

Las **Unidades Especialistas** son el nivel de ejecución del sistema. Cada unidad está compuesta por tres agentes (Director, Ejecutor, Archivador) que trabajan en conjunto para producir outputs validados y auditables.

---

## Patrón Triunvirato

Cada unidad especialista implementa el patrón **Triunvirato**:

```
UNIDAD ESPECIALISTA
│
├── Director (El Planificador)
│   ├── Planificación y estrategia
│   ├── Delegación de tareas
│   ├── Consolidación de resultados
│   └── Control de calidad final
│
├── Ejecutor (El Implementador)
│   ├── Ejecución de comandos
│   ├── Cálculos y generación
│   ├── Manipulación de archivos
│   └── Interacción con APIs
│
└── Archivador (El Persistente)
    ├── Observación silenciosa
    ├── Validación de coherencia
    ├── Persistencia en Vault
    └── Indexación semántica (RAG)
```

---

## Unidades Disponibles

### Por Catedrático (Jefatura)

| Catedrático | Código | Unidades |
|-------------|--------|----------|
| **JEF-CON** | CON | Académico, General |
| **JEF-ING** | ING | Desarrollo, Infraestructura |
| **JEF-OPE** | OPE | Hostelería |
| **JEF-RHU** | RHU | Deportes, *(dominios dinámicos)* |
| **JEF-REX** | REX | Criptomonedas, Finanzas |
| **JEF-COM** | COM | Idiomas |

### Unidades Predefinidas

| ID | Unidad | Namespace | Catedrático |
|----|--------|-----------|-------------|
| **ESP-DES-UNI-001** | Desarrollo | /dev | JEF-ING |
| **ESP-INF-UNI-001** | Infraestructura | /infra | JEF-ING |
| **ESP-ACA-UNI-001** | Académico | /academico | JEF-CON |
| **ESP-GEN-UNI-001** | General | /general | JEF-CON |
| **ESP-HOS-UNI-001** | Hostelería | /hosteleria | JEF-OPE |
| **ESP-DEP-UNI-001** | Deportes | /fitness | JEF-RHU |
| **ESP-CRI-UNI-001** | Criptomonedas | /crypto | JEF-REX |
| **ESP-FIN-UNI-001** | Finanzas | /inversiones | JEF-REX |
| **ESP-IDI-UNI-001** | Idiomas | /english | JEF-COM |

---

## Flujo de Ejecución

```
Input del Catedrático
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DIRECTOR                                      │
│  1. Analiza la tarea                                             │
│  2. Consulta memoria de unidad                                  │
│  3. Define plan de ejecución                                    │
│  4. Prepara prompts para Ejecutor                               │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EJECUTOR                                      │
│  1. Recibe plan del Director                                    │
│  2. Ejecuta operaciones                                         │
│  3. Usa herramientas (shell, APIs, filesystem)                 │
│  4. Genera resultado                                            │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ARCHIVADOR                                    │
│  1. Observa todo el proceso                                     │
│  2. Valida coherencia del resultado                            │
│  3. Verifica contra políticas                                   │
│  4. Decide: aprobar o rechazar                                  │
│  5. Persiste en memoria                                         │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
    Output validado → Catedrático
```

---

## Permisos por Rol

| Capacidad | Director | Ejecutor | Archivador |
|-----------|----------|----------|------------|
| Ejecutar shell | ❌ | ✅ (validado) | ❌ |
| Ejecutar Python | ❌ | ✅ (sandbox) | ❌ |
| Leer archivos | ❌ | ✅ (sandbox) | ✅ (todos) |
| Escribir archivos | ❌ | ✅ (sandbox) | ✅ (Vault) |
| Acceso red externa | ❌ | ✅ (HTTP) | ❌ |
| Memoria persistente | ❌ | ❌ | ✅ |
| Generar embeddings | ❌ | ❌ | ✅ |
| Validar comandos | ✅ | ❌ | ❌ |
| Consolidar resultados | ✅ | ❌ | ❌ |

---

## Mecanismo de Consenso

Para que un output sea entregado, debe haber **consenso** en la unidad:

| Situación | Consenso Requerido |
|-----------|-------------------|
| Tarea normal | 2 de 3 agentes de acuerdo |
| Tarea crítica | 3 de 3 agentes de acuerdo |
| Conflicto | Escalar al Jefe de Dominio |

---

## Memoria de Unidad

Cada unidad tiene memoria compartida entre sus tres agentes:

```
unit_memory/
├── contexto/          # Contexto actual
├── decisiones/        # Decisiones tomadas
├── resultados/        # Resultados previos
├── lecciones/         # Lecciones aprendidas
└── embeddings/        # Vectores para RAG
```

---

## Creación Dinámica

La **Fábrica de Agentes** puede crear nuevas unidades:

1. Recibe plantilla de unidad
2. Instancia los tres agentes
3. Configura prompts y herramientas
4. Conecta a memoria y comunicación
5. Registra en el sistema

Ver: [03-agent-factory.md](./03-agent-factory.md)

---

## Configuración

```yaml
unidad_especialista:
  nombre: "esp-des-unidad"

  director:
    modelo: "glm-4.5-air"
    temperatura: 0.7
    max_tokens: 4096

  ejecutor:
    modelo: "glm-4.5-air"
    temperatura: 0.3
    herramientas:
      - shell-exec
      - filesystem
      - http-client
    sandbox:
      activado: true
      red: none
      memoria: 512m

  archivador:
    modelo: "glm-4.5-air"
    temperatura: 0.1
    acceso_memoria: full
    validacion_esticta: true

  consenso:
    umbral: 0.66  # 2/3
    timeout: 30000
```

---

## Métricas por Unidad

| Métrica | Descripción |
|---------|-------------|
| `unidad.peticiones.total` | Peticiones procesadas |
| `unidad.ejecucion.tiempo` | Tiempo de ejecución |
| `unidad.consenso.exito` | Tasa de consenso exitoso |
| `unidad.validacion.fallos` | Fallos de validación |

---

## Referencias

- [01-patron-triunvirato.md](./01-patron-triunvirato.md) - Patrón Tri-Agente
- [02-unidades-disponibles.md](./02-unidades-disponibles.md) - Unidades disponibles
- [03-agent-factory.md](./03-agent-factory.md) - Fábrica de Agentes
- [../05-NIVEL-1-CATEDRATICOS/00-overview.md](../05-NIVEL-1-CATEDRATICOS/00-overview.md) - Catedráticos
- [../07-NIVEL-3-SUBAGENTES/00-overview.md](../07-NIVEL-3-SUBAGENTES/00-overview.md) - Subagentes

---

**Documento:** Nivel ESP - Unidades Especialistas
**Ubicación:** `docs/06-NIVEL-2-ESPECIALISTAS/00-overview.md`
**Versión:** 2.1.0
**Fecha:** 2026-03-09
