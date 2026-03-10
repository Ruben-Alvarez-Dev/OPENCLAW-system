# Protocolo de Validación

**ID:** SIS-BIB-PRO-001-validacion
**Nivel:** Sistema
**Dominio:** Biblioteca
**Tipo:** Protocolo
**Versión:** 2.1.0

---

## Propósito

Garantizar la calidad y consistencia de todas las salidas generadas por las unidades especializadas.

---

## Ámbito de Aplicación

- Todas las unidades tri-agente (Nivel ESP)
- Respuestas a usuarios
- Artefactos generados
- Actualizaciones de memoria

---

## Proceso de Validación

### 1. Validación Automática (Archivador)

```
Entrada → Verificar formato → Verificar consistencia → Verificar calidad → Salida
```

### 2. Criterios de Validación

| Criterio | Descripción | Puntuación Mínima |
|----------|-------------|-------------------|
| Completitud | La respuesta aborda toda la solicitud | 8/10 |
| Precisión | Información correcta y verificable | 9/10 |
| Relevancia | Información útil para el contexto | 8/10 |
| Claridad | Comprensible para el usuario | 8/10 |
| Formato | Estructura apropiada | 9/10 |

### 3. Flujo de Aprobación

```
Puntuación >= 8 → Aprobado automáticamente
Puntuación 6-7 → Requiere revisión del Director
Puntuación < 6 → Rechazado, nueva ejecución
```

---

## Métricas

```yaml
metricas:
  tasa_aprobacion: 95%
  tiempo_medio_validacion: 2s
  falsos_positivos: <1%
```

---

**Protocolo:** Validación
**Ubicación:** `biblioteca/protocolos/SIS-BIB-PRO-001-validacion.md`
