# Protocolo de Descubrimiento e Integración

**ID:** SIS-BIB-PRO-005-descubrimiento
**Nivel:** Sistema
**Dominio:** Biblioteca
**Tipo:** Protocolo
**Versión:** 2.1.0

---

## Propósito

Permitir que el sistema descubra e integre nuevos dominios y especialistas dinámicamente.

---

## Flujo

```
Petición → Router → ¿Dominio existe?
                      │
                      ├── SÍ → Enrutar a especialista
                      └── NO → Agent Factory → Crear especialista
```

---

## Agent Factory

```yaml
proceso:
  1_deteccion: identificar_dominio
  2_instanciacion: usar_template
  3_configuracion: inicializar_recursos
  4_registro: añadir_a_router
```

---

**Protocolo:** Descubrimiento
**Ubicación:** `biblioteca/protocolos/SIS-BIB-PRO-005-descubrimiento.md`
