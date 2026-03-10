# Motor de Conocimiento

**ID:** DOC-CNO-MOT-001
**Versión:** 2.1.0
**Fecha:** 2026-03-09
**Nivel:** Componente Core
**Dependencias:** [Arquitectura Maestra](../01-SISTEMA/00-arquitectura-maestra.md)

---

## Resumen

El Knowledge Engine gestiona las 5 capas de conocimiento del sistema, proporcionando acceso a fuentes verificadas, bibliotecas académicas, estándares técnicos y memoria del sistema. Utiliza RAG (Retrieval Augmented Generation) para consultas semánticas.

---

## 1. Arquitectura de 5 Capas

```
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 1: FOUNDATION MODEL KNOWLEDGE                             │
│  ────────────────────────────────────────────────────────────── │
│                                                                 │
│  Conocimiento base del modelo LLM                               │
│  • Matemáticas, lógica, física básica                          │
│  • Programación, economía general                              │
│  • Idiomas, historia general                                    │
│                                                                 │
│  Uso: Razonamiento, síntesis, inferencia                       │
│  Limitación: Puede estar desactualizado                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 2: LOCAL ACADEMIC LIBRARIES                               │
│  ────────────────────────────────────────────────────────────── │
│                                                                 │
│  Bibliotecas académicas estructuradas                           │
│  • Manuales universitarios                                      │
│  • Libros de ingeniería, medicina, derecho                      │
│  • Textos técnicos especializados                               │
│                                                                 │
│  Acceso: Vector search (RAG)                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 3: TECHNICAL STANDARDS & NORMS                            │
│  ────────────────────────────────────────────────────────────── │
│                                                                 │
│  Estándares y normativas                                        │
│  • ISO, IEEE, IEC                                               │
│  • Normativas nacionales (BOE, etc.)                           │
│  • Manuales industriales                                        │
│  • Protocolos técnicos                                          │
│                                                                 │
│  Uso: Validación de resultados                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 4: SYSTEM MEMORY (LESSONS LEARNED)                        │
│  ────────────────────────────────────────────────────────────── │
│                                                                 │
│  Conocimiento generado por el sistema                           │
│  • Decisiones técnicas tomadas                                  │
│  • Soluciones probadas y validadas                              │
│  • Errores detectados y corregidos                              │
│  • Procedimientos optimizados                                   │
│                                                                 │
│  Evolución: Aprendizaje acumulativo                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 5: EXTERNAL RESEARCH SOURCES                              │
│  ────────────────────────────────────────────────────────────── │
│                                                                 │
│  Investigación externa controlada                               │
│  • Papers académicos (arXiv, PubMed)                           │
│  • Repositorios científicos                                     │
│  • Documentación técnica oficial                                │
│                                                                 │
│  Filtro: Solo fuentes verificadas                              │
│  EVITAR: blogs, foros, opiniones sin fuente                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Fuentes de Conocimiento Personal

### Estructura de Directorios

```
knowledge_sources/
│
├── personal/                    # Documentación del usuario
│   ├── dev/                     # Ingeniería y desarrollo
│   │   ├── arquitectura_microservicios.pdf
│   │   ├── notas_cluster_openclaw.md
│   │   └── patrones_diseño/
│   │
│   ├── infra/                   # Infraestructura
│   │   ├── configs_servidores/
│   │   ├── guias_deployment/
│   │   └── runbooks/
│   │
│   ├── hosteleria/              # Gastronomía y F&B
│   │   ├── procedimientos_cocina/
│   │   ├── recetas/
│   │   ├── estandares_calidad/
│   │   └── gestion_restaurante/
│   │
│   ├── deportes/                # Fitness y deportes
│   │   ├── programas_entrenamiento/
│   │   ├── rutinas/
│   │   └── nutricion_deportiva/
│   │
│   └── general/                 # Conocimiento general
│
├── academic/                    # Bibliotecas académicas
│   ├── engineering/
│   ├── medicine/
│   ├── law/
│   └── finance/
│
└── standards/                   # Estándares técnicos
    ├── iso/
    ├── ieee/
    └── regulations/
```

---

## 3. Proceso de Ingesta de Documentos

### Pipeline de Ingesta

```
Documento
    │
    ▼
┌─────────────────┐
│ 1. LOADER       │  Cargar PDF, MD, TXT, DOCX
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 2. CHUNKER      │  Dividir en fragmentos (chunk_size=1000, overlap=200)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 3. METADATA     │  Extraer y añadir metadatos
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 4. EMBEDDER     │  Generar embeddings vectoriales
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 5. INDEXER      │  Almacenar en vector database
└─────────────────┘
```

### Implementación de Referencia

```python
from langchain.document_loaders import DirectoryLoader, PyPDFLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain.vectorstores import Chroma

class KnowledgeIngestor:
    def __init__(self, persist_directory: str):
        self.embeddings = OpenAIEmbeddings()
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200
        )
        self.persist_directory = persist_directory

    def ingest_directory(self, source_path: str, domain: str):
        # Cargar documentos
        loader = DirectoryLoader(source_path, glob="**/*.md")
        docs = loader.load()

        # Añadir metadatos
        for doc in docs:
            doc.metadata["domain"] = domain
            doc.metadata["source_type"] = "personal"
            doc.metadata["trust_level"] = "high"

        # Fragmentar
        chunks = self.text_splitter.split_documents(docs)

        # Indexar
        vectorstore = Chroma.from_documents(
            chunks,
            self.embeddings,
            persist_directory=self.persist_directory
        )
        vectorstore.persist()

        return len(chunks)

    def ingest_pdf(self, pdf_path: str, domain: str, metadata: dict = None):
        loader = PyPDFLoader(pdf_path)
        docs = loader.load()

        for doc in docs:
            doc.metadata["domain"] = domain
            doc.metadata["source_type"] = "personal"
            if metadata:
                doc.metadata.update(metadata)

        chunks = self.text_splitter.split_documents(docs)

        vectorstore = Chroma.from_documents(
            chunks,
            self.embeddings,
            persist_directory=self.persist_directory
        )
        vectorstore.persist()

        return len(chunks)
```

---

## 4. Sistema de Consulta (RAG)

### Flujo de Consulta

```
Query
    │
    ▼
┌─────────────────────┐
│ 1. EMBEDDING QUERY  │  Convertir pregunta a vector
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 2. VECTOR SEARCH    │  Buscar documentos similares
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 3. METADATA FILTER  │  Filtrar por dominio, tipo, confianza
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 4. RERANKING        │  Reordenar por relevancia
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 5. CONTEXT BUILD    │  Construir contexto para LLM
└─────────────────────┘
```

### Implementación de Consulta

```python
from langchain.vectorstores import Chroma
from langchain_openai import OpenAIEmbeddings

class KnowledgeRetriever:
    def __init__(self, persist_directory: str):
        self.embeddings = OpenAIEmbeddings()
        self.vectorstore = Chroma(
            persist_directory=persist_directory,
            embedding_function=self.embeddings
        )

    def search(
        self,
        query: str,
        domain: str = None,
        source_type: str = None,
        trust_level: str = None,
        k: int = 5
    ) -> list:
        # Construir filtros
        filter_dict = {}
        if domain:
            filter_dict["domain"] = domain
        if source_type:
            filter_dict["source_type"] = source_type
        if trust_level:
            filter_dict["trust_level"] = trust_level

        # Búsqueda semántica
        retriever = self.vectorstore.as_retriever(
            search_kwargs={
                "k": k,
                "filter": filter_dict if filter_dict else None
            }
        )

        docs = retriever.get_relevant_documents(query)
        return docs

    def search_with_priority(
        self,
        query: str,
        domain: str = None
    ) -> list:
        """Búsqueda con priorización de fuentes"""

        results = []

        # Prioridad 1: Memoria del sistema
        system_docs = self.search(
            query,
            source_type="system_memory",
            domain=domain,
            k=3
        )
        results.extend(system_docs)

        # Prioridad 2: Fuentes personales
        personal_docs = self.search(
            query,
            source_type="personal",
            domain=domain,
            k=5
        )
        results.extend(personal_docs)

        # Prioridad 3: Bibliotecas académicas
        academic_docs = self.search(
            query,
            source_type="academic",
            domain=domain,
            k=3
        )
        results.extend(academic_docs)

        # Prioridad 4: Estándares
        standards_docs = self.search(
            query,
            source_type="standards",
            k=2
        )
        results.extend(standards_docs)

        return results[:10]  # Top 10 resultados
```

---

## 5. Metadatos de Documentos

### Esquema de Metadatos

```json
{
  "id": "doc-uuid",
  "filename": "arquitectura_microservicios.pdf",
  "domain": "dev",
  "source_type": "personal",
  "trust_level": "high",
  "author": "ruben",
  "created_at": "2026-03-09T10:00:00Z",
  "indexed_at": "2026-03-09T10:05:00Z",
  "chunk_index": 5,
  "total_chunks": 42,
  "tags": ["microservicios", "arquitectura", "distribuido"],
  "language": "es"
}
```

### Niveles de Confianza

| Nivel | Descripción | Uso |
|-------|-------------|-----|
| `high` | Documentos personales, estándares oficiales | Prioridad máxima |
| `medium` | Fuentes académicas verificadas | Prioridad secundaria |
| `low` | Investigación externa, web | Solo si no hay otras fuentes |

---

## 6. Fuentes Fiables vs No Fiables

### Fuentes Fiables (Permitidas)

| Tipo | Ejemplos |
|------|----------|
| **Universidades** | MIT OCW, Stanford, Coursera |
| **Organismos oficiales** | ISO, IEEE, OMS, FAO |
| **Repositorios científicos** | arXiv, PubMed, IEEE Xplore |
| **Documentación técnica** | Docs oficiales de frameworks |
| **Manuales profesionales** | O'Reilly, Springer |

### Fuentes No Fiables (Evitar)

| Tipo | Ejemplos |
|------|----------|
| **Blogs personales** | Medium posts sin revisión |
| **Foros** | Reddit, StackOverflow (como única fuente) |
| **Redes sociales** | Twitter, LinkedIn |
| **Wikipedia** | Usar con precaución, verificar fuentes |

---

## 7. Integración con Agentes

### Consulta desde Unidades Especialistas

```python
class SpecialistUnit:
    def __init__(self, knowledge_retriever: KnowledgeRetriever):
        self.retriever = knowledge_retriever

    def process_query(self, query: str, domain: str) -> dict:
        # 1. Consultar conocimiento
        docs = self.retriever.search_with_priority(query, domain)

        # 2. Construir contexto
        context = self.build_context(docs)

        # 3. Generar respuesta con LLM
        response = self.llm.generate(
            context=context,
            query=query
        )

        # 4. Citar fuentes
        response.sources = [doc.metadata for doc in docs]

        return response
```

### Flujo en Tri-Agente

```
Consulta: "¿Cómo implementar rate limiting en API?"

Director:
├── Consulta Motor de Conocimiento
├── Recibe documentos relevantes
├── Planifica enfoque

Ejecutor:
├── Recibe plan + contexto
├── Genera implementación
├── Basada en fuentes

Archivador:
├── Valida contra estándares
├── Guarda solución en memoria
└── Indexa para futuras consultas
```

---

## 8. Comando de Ingesta

### CLI Interface

```bash
# Ingerir directorio completo
/openclaw knowledge ingest ./mis_docs/ --domain dev --source personal

# Ingerir PDF individual
/openclaw knowledge ingest manual.pdf --domain infra --trust-level high

# Ver estadísticas de conocimiento
/openclaw knowledge stats --domain dev

# Buscar en conocimiento
/openclaw knowledge search "arquitectura microservicios" --domain dev
```

---

## 9. Configuración

### Archivo de Configuración

```json
{
  "knowledge_engine": {
    "vector_db": {
      "type": "chroma",
      "persist_directory": "/data/knowledge_db",
      "embedding_model": "text-embedding-3-small",
      "embedding_provider": "openai"
    },

    "chunking": {
      "chunk_size": 1000,
      "chunk_overlap": 200,
      "separators": ["\n\n", "\n", ". ", " "]
    },

    "search": {
      "default_k": 5,
      "hybrid_search": true,
      "mmr": true,
      "mmr_diversity": 0.3
    },

    "cache": {
      "enabled": true,
      "ttl_seconds": 3600,
      "max_size_mb": 500
    }
  }
}
```

---

## 10. Métricas

| Métrica | Descripción | Target |
|---------|-------------|--------|
| **Retrieval Accuracy** | Precisión de documentos recuperados | > 85% |
| **Query Latency** | Tiempo de consulta | < 200ms |
| **Index Size** | Tamaño del índice vectorial | Track |
| **Documents Indexed** | Número de documentos | Track |
| **Cache Hit Rate** | % de consultas en cache | > 40% |

---

## Referencias

- [Arquitectura Maestra](../01-SISTEMA/00-arquitectura-maestra.md)
- [Arquitectura de Memoria](../09-MEMORIA/00-arquitectura-memoria.md)

---

**Documento:** Motor de Conocimiento
**Ubicación:** `docs/10-CONOCIMIENTO/00-knowledge-engine.md`
**Versión:** 2.1.0
**Fecha:** 2026-03-09
