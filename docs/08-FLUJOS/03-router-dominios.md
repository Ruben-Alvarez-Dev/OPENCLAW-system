# Router de Dominios - Sistema de Enrutamiento

**ID:** DOC-FLU-ROU-001
**Versión:** 2.1.0
**Fecha:** 2026-03-09
**Nivel:** Componente Core
**Dependencias:** [Arquitectura Maestra](../01-SISTEMA/00-arquitectura-maestra.md)

---

## Resumen

El Router de Dominios es el componente responsable de determinar qué dominio o unidad especialista debe manejar cada petición del usuario. Soporta dos modos de routing: explícito (via namespaces) e implícito (via clasificación semántica).

---

## 1. Arquitectura del Router

```
┌─────────────────────────────────────────────────────────────────┐
│                      ROUTER DE DOMINIOS                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐                   │
│  │  DETECTOR DE    │    │  CLASIFICADOR   │                   │
│  │  NAMESPACE      │    │  SEMÁNTICO      │                   │
│  │  (/dev, /infra) │    │  (NLP/Embed)    │                   │
│  └────────┬────────┘    └────────┬────────┘                   │
│           │                      │                              │
│           └──────────┬───────────┘                              │
│                      ▼                                          │
│           ┌─────────────────────┐                               │
│           │  RESOLVER DE        │                               │
│           │  DOMINIO            │                               │
│           │  (mapeo a Jefe)     │                               │
│           └──────────┬──────────┘                               │
│                      │                                          │
│                      ▼                                          │
│           ┌─────────────────────┐                               │
│           │  VERIFICACIÓN DE    │                               │
│           │  EXISTENCIA         │                               │
│           │  (Registro Agentes) │                               │
│           └──────────┬──────────┘                               │
│                      │                                          │
│         ┌────────────┴────────────┐                            │
│         ▼                         ▼                            │
│  ┌─────────────┐          ┌─────────────┐                      │
│  │  EXISTE     │          │  NO EXISTE  │                      │
│  │  Enrutar a │          │  Fábrica de │                      │
│  │  Jefe       │          │  Agentes    │                      │
│  └─────────────┘          └─────────────┘                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Namespaces Disponibles

### Namespaces Principales

| Namespace | Dominio | Jefe Asignado | Descripción |
|-----------|---------|---------------|-------------|
| `/dev` | Desarrollo | JEF-ING | Programación, arquitectura software, debugging |
| `/infra` | Infraestructura | JEF-ING | Servidores, DevOps, networking, cloud |
| `/crypto` | Criptomonedas | JEF-REX | Blockchain, DeFi, trading crypto |
| `/inversiones` | Inversiones | JEF-REX | Finanzas, trading tradicional, análisis |
| `/hosteleria` | Hostelería | JEF-OPE | Gastronomía, F&B, gestión restaurante |
| `/f&b` | Food & Beverage | JEF-OPE | Alias de hosteleria |
| `/fitness` | Deportes | JEF-RHU | Entrenamiento, nutrición deportiva, salud |
| `/academico` | Académico | JEF-CON | Preparación exámenes, estudio |
| `/general` | General | JEF-CON | Propósito general, fallback |
| `/english` | Idiomas | JEF-COM | Aprendizaje de idiomas |

### Mapeo a Catedráticos

```
Namespaces → Catedrático

/dev, /infra          → JEF-ING (Jefe de Ingeniería)
/hosteleria, /f&b     → JEF-OPE (Jefe de Operaciones)
/crypto, /inversiones → JEF-REX (Jefe de Relaciones Externas)
/fitness              → JEF-RHU (Jefe de Recursos Humanos)
/academico, /general  → JEF-CON (Jefe de Conocimiento)
/english              → JEF-COM (Jefe de Comunicación)
```

---

## 3. Modo Explícito (Namespace)

### Proceso

```
Input: "/dev diseñar arquitectura de cluster"

1. Detección de namespace
   - Extraer: "/dev"

2. Validación
   - ¿Es un namespace válido? → Sí

3. Mapeo
   - /dev → JEF-ING

4. Routing
   - Enviar a JEF-ING con resto del input
   - Input restante: "diseñar arquitectura de cluster"
```

### Ejemplos

| Input | Namespace Detectado | Route a |
|-------|-------------------|---------|
| `/dev crear API REST` | `/dev` | JEF-ING |
| `/infra configurar VPS Ubuntu` | `/infra` | JEF-ING |
| `/hosteleria diseñar carta de vinos` | `/hosteleria` | JEF-OPE |
| `/fitness plan entrenamiento maratón` | `/fitness` | JEF-RHU |
| `/academico temario derecho` | `/academico` | JEF-CON |

---

## 4. Modo Implícito (Clasificación Semántica)

### Proceso

```
Input: "Diseñar una infraestructura distribuida para alta disponibilidad"

1. Detección de namespace
   - ¿Empieza con /? → No
   - Modo implícito activado

2. Clasificación semántica
   - Embedding del input
   - Búsqueda de similitud con dominios conocidos
   - Análisis de keywords

3. Resultado del análisis:
   - "infraestructura" → /infra
   - "distribuida" → /infra, /dev
   - "alta disponibilidad" → /infra

4. Puntuación:
   - /infra: 0.85
   - /dev: 0.45
   - /hosteleria: 0.02

5. Selección:
   - Mayor puntuación: /infra → JEF-ING
```

### Implementación de Clasificación

```python
class RouterSemantico:
    def __init__(self, modelo_embedding, vectores_dominio):
        self.embedder = modelo_embedding
        self.vectores_dominio = vectores_dominio  # Pre-computados

    def clasificar(self, texto: str) -> tuple[str, float]:
        # 1. Generar embedding del input
        embedding_input = self.embedder.embed(texto)

        # 2. Calcular similitud con cada dominio
        puntuaciones = {}
        for dominio, vector_dom in self.vectores_dominio.items():
            puntuaciones[dominio] = similitud_coseno(embedding_input, vector_dom)

        # 3. Retornar el dominio con mayor puntuación
        mejor_dominio = max(puntuaciones, key=puntuaciones.get)
        return mejor_dominio, puntuaciones[mejor_dominio]
```

### Dominios Pre-Definidos para Clasificación

```python
DESCRIPCIONES_DOMINIO = {
    "/dev": "programación desarrollo software código arquitectura API backend frontend testing debugging",
    "/infra": "servidores infraestructura DevOps cloud Docker Kubernetes networking VPS Ubuntu Linux",
    "/crypto": "blockchain criptomonedas Bitcoin Ethereum DeFi smart contracts trading crypto",
    "/inversiones": "inversiones finanzas trading acciones bolsa análisis financiero portfolio",
    "/hosteleria": "hosteleria gastronomía restaurante cocina vinos carta F&B servicio sala",
    "/fitness": "deportes entrenamiento ejercicio gimnasio rutina nutrición salud marathon musculación",
    "/academico": "oposiciones exámenes estudio académico temario preparación opositar",
    "/english": "inglés idiomas learning vocabulary grammar speaking writing"
}
```

---

## 5. Verificación de Existencia

### Registro de Agentes

El Router consulta el Registro de Agentes para verificar si un dominio existe:

```python
class RegistroAgentes:
    def __init__(self, conexion_db):
        self.db = conexion_db

    def dominio_existe(self, namespace: str) -> bool:
        return self.db.query(
            "SELECT 1 FROM dominios WHERE namespace = ?",
            namespace
        ) is not None

    def obtener_info_dominio(self, namespace: str) -> dict:
        return self.db.query(
            "SELECT * FROM dominios WHERE namespace = ?",
            namespace
        )
```

### Flujo de Verificación

```
Namespace detectado: /floristeria
          │
          ▼
┌─────────────────────┐
│ Registro de Agentes │
│ dominio_existe()?   │
└──────────┬──────────┘
           │
      ┌────┴────┐
      │         │
   EXISTE   NO_EXISTE
      │         │
      ▼         ▼
┌──────────┐ ┌─────────────────┐
│ Enrutar  │ │ Escalar a       │
│ a Jefe   │ │ Fábrica Agentes │
└──────────┘ └─────────────────┘
```

---

## 6. Creación Dinámica de Dominios

Cuando el dominio no existe, el Router escala a la Fábrica de Agentes:

```
┌─────────────────────────────────────────────────────────────────┐
│  INPUT: /floristeria diseñar decoración para boda              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  ROUTER                                                         │
│  1. Namespace: /floristeria                                    │
│  2. Verificación registro: NO EXISTE                           │
│  3. Escalar a Fábrica de Agentes                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  FÁBRICA DE AGENTES (bajo JEF-RHU)                             │
│  1. Seleccionar plantilla de especialista                      │
│  2. Configurar para dominio "floristeria"                      │
│  3. Crear Unidad Floristería (tri-agente)                      │
│  4. Registrar en Registro de Agentes                           │
│  5. Retornar info de routing                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  ROUTER (continúa)                                              │
│  6. Enrutar a nuevo dominio /floristeria                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. Resolución de Ambigüedad

### Casos Ambiguos

```
Input: "Analizar rendimiento del sistema"

Posibles dominios:
- /dev (análisis de código)
- /infra (análisis de servidores)
- /academico (análisis académico)

Estrategia de resolución:
1. Contexto previo de conversación
2. Puntuación semántica ponderada
3. Si empate → preguntar al usuario
```

### Implementación

```python
def resolver_ambiguedad(texto: str, puntuaciones: dict, umbral: float = 0.1) -> str:
    # Ordenar por puntuación
    dominios_ordenados = sorted(puntuaciones.items(), key=lambda x: x[1], reverse=True)

    # Si la diferencia entre top 2 es menor que umbral
    if dominios_ordenados[0][1] - dominios_ordenados[1][1] < umbral:
        # Ambiguo - solicitar clarificación
        return solicitar_clarificacion(dominios_ordenados[:3])

    return dominios_ordenados[0][0]
```

---

## 8. API del Router

### Interfaz

```python
class RouterDominios:
    def enrutar(self, input_usuario: str, contexto: dict = None) -> ResultadoRouting:
        """
        Enrutar input del usuario al dominio apropiado.

        Args:
            input_usuario: Texto del usuario
            contexto: Contexto de conversación previa

        Returns:
            ResultadoRouting con:
            - namespace: Namespace destino
            - jefe: Catedrático asignado
            - confianza: Nivel de confianza
            - es_nuevo_dominio: Si es un dominio recién creado
        """
        pass
```

### Ejemplo de Uso

```python
router = RouterDominios(registro, fabrica_agentes, modelo_embedding)

# Caso explícito
resultado = router.enrutar("/dev crear API REST")
# → ResultadoRouting(namespace="/dev", jefe="JEF-ING", confianza=1.0, es_nuevo_dominio=False)

# Caso implícito
resultado = router.enrutar("Diseñar plan de entrenamiento")
# → ResultadoRouting(namespace="/fitness", jefe="JEF-RHU", confianza=0.82, es_nuevo_dominio=False)

# Caso dominio nuevo
resultado = router.enrutar("/albanileria construir muro")
# → ResultadoRouting(namespace="/albanileria", jefe="JEF-OPE", confianza=0.75, es_nuevo_dominio=True)
```

---

## 9. Configuración

### Archivo de Configuración

```json
{
  "router": {
    "modo": "hibrido",
    "prefijo_explicito": "/",
    "umbral_confianza": 0.6,
    "umbral_ambiguedad": 0.1,
    "jefe_fallback": "JEF-CON",

    "namespaces": {
      "/dev": {"jefe": "JEF-ING", "prioridad": 1},
      "/infra": {"jefe": "JEF-ING", "prioridad": 1},
      "/hosteleria": {"jefe": "JEF-OPE", "prioridad": 1},
      "/fitness": {"jefe": "JEF-RHU", "prioridad": 1},
      "/crypto": {"jefe": "JEF-REX", "prioridad": 1},
      "/inversiones": {"jefe": "JEF-REX", "prioridad": 1},
      "/academico": {"jefe": "JEF-CON", "prioridad": 1},
      "/general": {"jefe": "JEF-CON", "prioridad": 1},
      "/english": {"jefe": "JEF-COM", "prioridad": 1}
    },

    "clasificador_semantico": {
      "modelo": "text-embedding-3-small",
      "proveedor": "openai",
      "cache_embeddings": true
    }
  }
}
```

---

## 10. Métricas y Monitoreo

### Métricas Clave

| Métrica | Descripción | Objetivo |
|---------|-------------|----------|
| **Precisión de Routing** | % de routings correctos | > 95% |
| **Tiempo de Clasificación** | Tiempo de clasificación semántica | < 100ms |
| **Routing Explícito** | % de comandos con namespace explícito | > 60% |
| **Dominios Nuevos Creados** | Dominios creados dinámicamente | Tracking |
| **Tasa de Ambigüedad** | % de inputs ambiguos | < 5% |

### Logs

```
[ROUTER] 2026-03-09 10:30:15 | INFO  | Route explícito: /dev → JEF-ING
[ROUTER] 2026-03-09 10:30:18 | INFO  | Route semántico: "plan de entrenamiento" → /fitness (0.82)
[ROUTER] 2026-03-09 10:30:22 | WARN  | Input ambiguo, solicitando clarificación
[ROUTER] 2026-03-09 10:30:25 | INFO  | Nuevo dominio creado: /floristeria → JEF-OPE
```

---

## Referencias

- [../01-SISTEMA/00-arquitectura-maestra.md](../01-SISTEMA/00-arquitectura-maestra.md) - Arquitectura Maestra
- [../06-NIVEL-2-ESPECIALISTAS/03-agent-factory.md](../06-NIVEL-2-ESPECIALISTAS/03-agent-factory.md) - Fábrica de Agentes
- [00-comunicaciones.md](00-comunicaciones.md) - Comunicaciones

---

**Documento:** Router de Dominios
**Ubicación:** `docs/08-FLUJOS/03-router-dominios.md`
**Versión:** 2.1.0
**Fecha:** 2026-03-09
