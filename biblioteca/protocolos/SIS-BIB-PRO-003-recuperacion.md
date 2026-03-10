# Protocolo de Recuperación

**ID:** SIS-BIB-PRO-003-recuperacion
**Nivel:** Sistema
**Dominio:** Biblioteca
**Tipo:** Protocolo
**Versión:** 2.1.0

---

## Propósito

Definir los mecanismos de recuperación de información desde las capas de conocimiento y memoria.

---

## Orden de Recuperación (Prioridad)

```
1. Memoria del Sistema     → Decisiones previas, lecciones aprendidas
2. Conocimiento Personal   → Fuentes proporcionadas por el usuario
3. Bibliotecas Académicas  → Manuales, libros técnicos
4. Estándares Técnicos     → ISO, IEEE, normativas
5. Investigación Externa   → Papers, fuentes verificadas
```

---

## Caché de Recuperación

```yaml
cache:
  habilitado: true
  ttl:
    conocimiento_estatico: 24h
    conocimiento_dinamico: 1h
    datos_tiempo_real: 5min
```

---

**Protocolo:** Recuperación
**Ubicación:** `biblioteca/protocolos/SIS-BIB-PRO-003-recuperacion.md`
