# Fábrica de Agentes - Sistema de Creación Dinámica

**ID:** DOC-ESP-FAB-001
**Versión:** 2.1.0
**Fecha:** 2026-03-09
**Nivel:** Componente Core
**Dependencias:** [Arquitectura Maestra](../01-SISTEMA/00-arquitectura-maestra.md), [Router de Dominios](../08-FLUJOS/03-router-dominios.md)

---

## Resumen

La Fábrica de Agentes es el sistema responsable de crear dinámicamente nuevos dominios y unidades especializadas cuando el sistema detecta que no tiene expertise en un área solicitada. Opera bajo el Catedrático **JEF-RHU** (Jefe de Recursos Humanos).

---

## 1. Visión General

```
┌─────────────────────────────────────────────────────────────────┐
│                      FÁBRICA DE AGENTES                         │
│                 (Bajo JEF-RHU - Recursos Humanos)               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐     ┌─────────────────┐                   │
│  │  NUEVO DOMINIO  │────►│  SELECTOR DE    │                   │
│  │  REQUEST        │     │  PLANTILLA      │                   │
│  └─────────────────┘     └────────┬────────┘                   │
│                                   │                             │
│                                   ▼                             │
│  ┌──────────────────────────────────────────────────────┐      │
│  │                  BIBLIOTECA DE PLANTILLAS             │      │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐    │      │
│  │  │Plantilla│ │Plantilla│ │Plantilla│ │Plantilla│    │      │
│  │  │Especial.│ │Investig.│ │Creativa │ │Soporte  │    │      │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘    │      │
│  └──────────────────────────────────────────────────────┘      │
│                                   │                             │
│                                   ▼                             │
│  ┌─────────────────┐     ┌─────────────────┐                   │
│  │  CONFIGURACIÓN  │────►│  ENSAMBLADOR    │                   │
│  │  CONOCIMIENTO   │     │  DE UNIDAD      │                   │
│  └─────────────────┘     └────────┬────────┘                   │
│                                   │                             │
│                                   ▼                             │
│  ┌─────────────────┐     ┌─────────────────┐                   │
│  │  UNIDAD CREADA  │────►│  ACTUALIZACIÓN  │                   │
│  │  (tri-agente)   │     │  REGISTRO       │                   │
│  └─────────────────┘     └─────────────────┘                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Flujo de Creación

### Proceso Completo

```
1. ROUTER detecta dominio no existente
   Input: "/floristeria diseñar decoración boda"
   │
   ▼
2. RESOLVER DE DOMINIO verifica en Registro de Agentes
   Result: "/floristeria" no existe
   │
   ▼
3. ESCALAR a JEF-RHU (Jefe de Recursos Humanos)
   JEF-RHU activa Fábrica de Agentes
   │
   ▼
4. SELECTOR DE PLANTILLA elige plantilla base
   Plantilla: "Plantilla Especialista"
   │
   ▼
5. CONFIGURACIÓN DE FUENTES DE CONOCIMIENTO
   - Buscar fuentes de conocimiento
   - Identificar material académico
   - Configurar vector store
   │
   ▼
6. ENSAMBLADOR DE UNIDAD crea tri-unidad
   Director + Ejecutor + Archivador
   Configurados para dominio "floristeria"
   │
   ▼
7. ACTUALIZACIÓN DE REGISTRO
   - Registrar dominio en Registro de Agentes
   - Registrar unidad en Registro de Unidades
   - Actualizar tabla de routing
   │
   ▼
8. ROUTING al nuevo dominio
   Request original enviado a nueva unidad
```

---

## 3. Estructura de Plantillas

### Plantilla de Especialista (Tri-Unidad)

```yaml
# biblioteca/plantillas/SIS-BIB-PLA-001-especialista_base.yaml

nombre: plantilla_especialista
version: 2.1.0
descripcion: Plantilla base para unidades especializadas tri-agente

componentes:
  director:
    rol: "Supervisor y planificador del dominio {DOMINIO}"
    prompt_sistema: |
      Eres el Director de la unidad especialista en {DOMINIO}.
      Tu responsabilidad es:
      - Planificar enfoques para resolver problemas
      - Delegar tareas al Ejecutor
      - Consolidar resultados
      - Asegurar calidad antes de entregar

      Contexto del dominio:
      {CONTEXTO_DOMINIO}

    herramientas: []
    permisos:
      filesystem: "none"
      shell: "none"
      network: "internal_only"

    modelo:
      proveedor: "zai"
      modelo_id: "glm-4.5-air"
      temperatura: 0.3

  ejecutor:
    rol: "Ejecutor especializado en {DOMINIO}"
    prompt_sistema: |
      Eres el Ejecutor especializado en {DOMINIO}.
      Tu responsabilidad es:
      - Ejecutar tareas delegadas por el Director
      - Utilizar herramientas disponibles
      - Generar resultados concretos

      Contexto del dominio:
      {CONTEXTO_DOMINIO}

    herramientas:
      - shell_exec
      - python_interpreter
      - file_system
      - web_search
      - knowledge_retrieval

    permisos:
      filesystem: "sandbox"
      shell: "validated"
      network: "http_allowed"

    modelo:
      proveedor: "zai"
      modelo_id: "glm-4.5-air"
      temperatura: 0.5

  archivador:
    rol: "Archivador y validador del dominio {DOMINIO}"
    prompt_sistema: |
      Eres el Archivador de la unidad especialista en {DOMINIO}.
      Tu responsabilidad es:
      - Validar coherencia de resultados
      - Documentar procedimientos
      - Indexar conocimiento en Vault
      - Mantener memoria de la unidad

      Contexto del dominio:
      {CONTEXTO_DOMINIO}

    herramientas:
      - memory
      - embeddings
      - file_system_readonly

    permisos:
      filesystem: "vault_write"
      shell: "none"
      network: "none"

    modelo:
      proveedor: "zai"
      modelo_id: "glm-4.5-air"
      temperatura: 0.2

config_memoria:
  memoria_agente: true
  memoria_unidad: true
  memoria_dominio: "{DOMINIO}"
  vector_db: "sqlite-vec"
  ruta_persistencia: "/memoria/dominios/{DOMINIO}/"

config_conocimiento:
  fuentes:
    - tipo: "academic"
      prioridad: 1
    - tipo: "standards"
      prioridad: 2
    - tipo: "web"
      prioridad: 3
      filtro: "solo_verificados"
```

### Plantillas Disponibles

| Plantilla | Uso | Ejemplos de Dominio |
|-----------|-----|---------------------|
| **plantilla_especialista** | Dominios técnicos/prácticos | /dev, /infra, /floristeria |
| **plantilla_investigacion** | Dominios académicos | /investigacion, /cuantica |
| **plantilla_creativa** | Dominios creativos | /diseño, /marketing |
| **plantilla_soporte** | Dominios de soporte | /legal, /traduccion |

---

## 4. Configuración de Fuentes de Conocimiento

### Proceso Automático

```python
class ConfiguradorFuentesConocimiento:
    def configurar_para_dominio(self, dominio: str, contexto_dominio: str) -> dict:
        """
        Configurar fuentes de conocimiento para nuevo dominio.
        """
        config = {
            "dominio": dominio,
            "fuentes": []
        }

        # 1. Buscar fuentes académicas
        fuentes_academicas = self.buscar_fuentes_academicas(contexto_dominio)
        config["fuentes"].extend(fuentes_academicas)

        # 2. Buscar estándares relacionados
        estandares = self.buscar_estandares(contexto_dominio)
        config["fuentes"].extend(estandares)

        # 3. Configurar vector store
        config["vector_store"] = self.configurar_vector_store(dominio)

        # 4. Indexar contenido inicial
        self.indexar_contenido_inicial(dominio, config["fuentes"])

        return config

    def buscar_fuentes_academicas(self, contexto: str) -> list:
        """Buscar fuentes académicas relevantes"""
        return [
            {"tipo": "academic", "query": contexto, "prioridad": 1}
        ]

    def buscar_estandares(self, contexto: str) -> list:
        """Buscar estándares relacionados"""
        return [
            {"tipo": "standards", "query": contexto, "prioridad": 2}
        ]
```

### Fuentes por Defecto

| Tipo | Prioridad | Descripción |
|------|-----------|-------------|
| **Academic** | 1 | Papers, manuales universitarios |
| **Standards** | 2 | ISO, IEEE, normativas |
| **Technical** | 3 | Documentación técnica oficial |
| **Web** | 4 | Solo fuentes verificadas |

---

## 5. Ensamblador de Unidades

### Implementación

```python
class EnsambladorUnidades:
    def __init__(self, cargador_plantillas, registro):
        self.plantillas = cargador_plantillas
        self.registro = registro

    def ensamblar_unidad(
        self,
        dominio: str,
        nombre_plantilla: str,
        contexto_dominio: str,
        config_conocimiento: dict
    ) -> UnidadEspecialista:
        """
        Ensamblar nueva unidad especialista tri-agente.
        """
        # 1. Cargar plantilla
        plantilla = self.plantillas.cargar(nombre_plantilla)

        # 2. Interpolar variables
        config = self.interpolar_plantilla(
            plantilla,
            dominio=dominio,
            contexto_dominio=contexto_dominio
        )

        # 3. Crear agentes individuales
        director = self.crear_agente(
            rol="director",
            config=config["director"],
            dominio=dominio
        )

        ejecutor = self.crear_agente(
            rol="ejecutor",
            config=config["ejecutor"],
            dominio=dominio
        )

        archivador = self.crear_agente(
            rol="archivador",
            config=config["archivador"],
            dominio=dominio
        )

        # 4. Crear unidad
        unidad = UnidadEspecialista(
            dominio=dominio,
            director=director,
            ejecutor=ejecutor,
            archivador=archivador,
            config_memoria=config["config_memoria"],
            config_conocimiento=config_conocimiento
        )

        # 5. Registrar
        self.registro.registrar_dominio(dominio, unidad)

        return unidad

    def interpolar_plantilla(self, plantilla: dict, **kwargs) -> dict:
        """Interpolar variables en plantilla"""
        import yaml
        config_str = yaml.dump(plantilla)
        for key, value in kwargs.items():
            config_str = config_str.replace(f"{{{key}}}", str(value))
        return yaml.safe_load(config_str)
```

---

## 6. Registro de Agentes

### Estructura de Datos

```python
class RegistroAgentes:
    def __init__(self, conexion_db):
        self.db = conexion_db

    def registrar_dominio(
        self,
        namespace: str,
        unidad: UnidadEspecialista,
        jefe: str,
        metadata: dict = None
    ):
        """Registrar nuevo dominio"""
        self.db.execute("""
            INSERT INTO dominios (namespace, jefe, creado_en, metadata)
            VALUES (?, ?, ?, ?)
        """, namespace, jefe, datetime.now(), json.dumps(metadata))

        self.db.execute("""
            INSERT INTO unidades (namespace, unidad_id, agentes, config)
            VALUES (?, ?, ?, ?)
        """, namespace, unidad.id, json.dumps(unidad.agent_ids), unidad.config)

    def dominio_existe(self, namespace: str) -> bool:
        """Verificar si dominio existe"""
        result = self.db.query(
            "SELECT 1 FROM dominios WHERE namespace = ?",
            namespace
        )
        return result is not None

    def obtener_info_dominio(self, namespace: str) -> dict:
        """Obtener información del dominio"""
        return self.db.query(
            "SELECT * FROM dominios WHERE namespace = ?",
            namespace
        )

    def listar_dominios(self) -> list:
        """Listar todos los dominios"""
        return self.db.query("SELECT * FROM dominios ORDER BY creado_en")

    def obtener_unidades_dominio(self, namespace: str) -> list:
        """Obtener unidades de un dominio"""
        return self.db.query(
            "SELECT * FROM unidades WHERE namespace = ?",
            namespace
        )
```

### Esquema de Base de Datos

```sql
CREATE TABLE dominios (
    namespace TEXT PRIMARY KEY,
    jefe TEXT NOT NULL,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    esta_activo BOOLEAN DEFAULT TRUE,
    metadata JSON
);

CREATE TABLE unidades (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    namespace TEXT NOT NULL,
    unidad_id TEXT UNIQUE NOT NULL,
    agentes JSON NOT NULL,
    config JSON,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (namespace) REFERENCES dominios(namespace)
);

CREATE TABLE plantillas_agentes (
    nombre TEXT PRIMARY KEY,
    version TEXT NOT NULL,
    descripcion TEXT,
    plantilla YAML NOT NULL,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 7. Ejemplos de Creación

### Ejemplo 1: Floristería

```
Input: "/floristeria diseñar decoración para boda"

1. Router detecta: /floristeria no existe
2. Fábrica de Agentes activada
3. Plantilla: plantilla_especialista
4. Dominio: floristeria
5. Contexto: "diseño floral, arreglos, decoración eventos"
6. Fuentes: manuales de floristería, guías de diseño
7. Unidad creada:
   - Floristeria Director (planificación de diseños)
   - Floristeria Ejecutor (composiciones, logística)
   - Floristeria Archivador (estilos, normas, proveedores)
8. Registrado y routing activado
```

### Ejemplo 2: Ingeniería Automotriz

```
Input: "/autoengine reparar motor diesel"

1. Router detecta: /autoengine no existe
2. Fábrica de Agentes activada
3. Plantilla: plantilla_especialista
4. Dominio: ingenieria_automotriz
5. Contexto: "mecánica automotriz, diagnóstico, reparación"
6. Fuentes: manuales de ingeniería, especificaciones técnicas
7. Unidad creada:
   - Automotriz Director (diagnóstico, planificación)
   - Automotriz Ejecutor (procedimientos, herramientas)
   - Automotriz Archivador (especificaciones, manuales)
```

### Ejemplo 3: Física Cuántica

```
Input: "/cuantica explicar entrelazamiento cuántico"

1. Router detecta: /cuantica no existe
2. Fábrica de Agentes activada
3. Plantilla: plantilla_investigacion (académico)
4. Dominio: fisica_cuantica
5. Contexto: "física cuántica, mecánica cuántica, teoría"
6. Fuentes: papers académicos, textbooks de física
7. Unidad creada:
   - Cuantica Director (análisis conceptual)
   - Cuantica Ejecutor (cálculos, simulaciones)
   - Cuantica Archivador (papers, teorías)
```

---

## 8. Política de Creación

### Reglas

1. **Siempre usar plantillas** - Nunca crear desde cero
2. **Validar contexto** - Requerir contexto mínimo del dominio
3. **Configurar fuentes** - Siempre configurar al menos 2 fuentes
4. **Registrar inmediatamente** - Registrar antes de usar
5. **Documentar creación** - Guardar log del proceso

### Validaciones

```python
class ValidadorCreacion:
    def validar_creacion_dominio(
        self,
        namespace: str,
        contexto_dominio: str,
        fuentes_conocimiento: list
    ) -> tuple[bool, list[str]]:
        """Validar que la creación es posible y apropiada"""
        errores = []

        # Namespace válido
        if not namespace.startswith("/"):
            errores.append("Namespace debe empezar con /")

        if len(namespace) < 2:
            errores.append("Namespace muy corto")

        if self.registro.dominio_existe(namespace):
            errores.append("Dominio ya existe")

        # Contexto suficiente
        if len(contexto_dominio) < 50:
            errores.append("Contexto insuficiente (mínimo 50 caracteres)")

        # Fuentes mínimas
        if len(fuentes_conocimiento) < 1:
            errores.append("Requiere al menos 1 fuente de conocimiento")

        return len(errores) == 0, errores
```

---

## 9. API de la Fábrica de Agentes

### Interfaz

```python
class APIFabricaAgentes:
    def crear_dominio(
        self,
        namespace: str,
        contexto_dominio: str,
        plantilla: str = "plantilla_especialista",
        auto_configurar: bool = True
    ) -> ResultadoCreacion:
        """
        Crear nuevo dominio y unidad especialista.

        Args:
            namespace: Namespace del dominio (ej: /floristeria)
            contexto_dominio: Descripción del dominio
            plantilla: Plantilla a usar
            auto_configurar: Configurar fuentes automáticamente

        Returns:
            ResultadoCreacion con:
            - exito: bool
            - unidad: UnidadEspecialista | None
            - dominio: str
            - errores: list[str]
        """
        pass

    def listar_plantillas(self) -> list[dict]:
        """Listar plantillas disponibles"""
        pass

    def obtener_info_dominio(self, namespace: str) -> dict:
        """Obtener información de un dominio"""
        pass

    def desactivar_dominio(self, namespace: str) -> bool:
        """Desactivar un dominio (no eliminar)"""
        pass
```

---

## 10. Integración con JEF-RHU

### Rol del Catedrático JEF-RHU

JEF-RHU es responsable de:
- Aprobar creaciones de nuevos dominios
- Supervisar calidad de unidades creadas
- Gestionar plantillas disponibles
- Mantener registro de capacidades del sistema

### Flujo de Aprobación

```
Request nuevo dominio
        │
        ▼
┌─────────────────┐
│ Fábrica Agentes │
│ Preparar unidad │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ JEF-RHU Review  │
│ ¿Aprobar?       │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
  APROBAR   RECHAZAR
    │         │
    ▼         ▼
┌─────────┐ ┌─────────┐
│Registrar│ │Solicitar│
│Activar  │ │Más info │
└─────────┘ └─────────┘
```

---

## Referencias

- [../01-SISTEMA/00-arquitectura-maestra.md](../01-SISTEMA/00-arquitectura-maestra.md) - Arquitectura Maestra
- [../08-FLUJOS/03-router-dominios.md](../08-FLUJOS/03-router-dominios.md) - Router de Dominios
- [../09-MEMORIA/00-arquitectura-memoria.md](../09-MEMORIA/00-arquitectura-memoria.md) - Arquitectura de Memoria
- [../10-CONOCIMIENTO/00-knowledge-engine.md](../10-CONOCIMIENTO/00-knowledge-engine.md) - Motor de Conocimiento
- [../../biblioteca/plantillas/SIS-BIB-PLA-001-especialista_base.yaml](../../biblioteca/plantillas/SIS-BIB-PLA-001-especialista_base.yaml) - Plantilla Especialista

---

**Documento:** Fábrica de Agentes
**Ubicación:** `docs/06-NIVEL-2-ESPECIALISTAS/03-agent-factory.md`
**Versión:** 2.1.0
**Fecha:** 2026-03-09
