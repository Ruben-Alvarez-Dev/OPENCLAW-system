# Anexo B: Configuración de Ollama

**ID:** DOC-ANX-OLL-001
**Propósito:** Guía completa de configuración y optimización de Ollama para OPENCLAW-system

---

## 1. Instalación

### 1.1 Instalación Estándar

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### 1.2 Verificación

```bash
ollama --version
# Output: ollama version is 0.x.x

curl http://127.0.0.1:11434/api/version
# Output: {"version":"0.x.x"}
```

---

## 2. Configuración de Seguridad

### 2.1 Bind a Localhost (CRÍTICO)

```bash
# Verificar bind actual
ss -tlnp | grep 11434

# Si muestra 0.0.0.0:11434, corregir:
sudo systemctl stop ollama

sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf << 'EOF'
[Service]
Environment="OLLAMA_HOST=127.0.0.1:11434"
EOF

sudo systemctl daemon-reload
sudo systemctl start ollama

# Verificar
ss -tlnp | grep 11434
# Debe mostrar: 127.0.0.1:11434
```

### 2.2 Firewall

```bash
# Asegurar que el puerto 11434 NO está expuesto
sudo ufw status | grep 11434
# No debe aparecer
```

---

## 3. Modelos Recomendados

### 3.1 Para VPS con 4-8GB RAM

| Modelo | Tamaño | Uso |
|--------|--------|-----|
| **llama3.2:3b** | ~2GB | Uso general, rápido |
| **llama3.2:1b** | ~1.3GB | Muy rápido, menos capacidad |
| **phi3:mini** | ~2.2GB | Alternativa ligera |

### 3.2 Para VPS con 16+ GB RAM

| Modelo | Tamaño | Uso |
|--------|--------|-----|
| **llama3.1:8b** | ~4.7GB | Mejor calidad |
| **mistral:7b** | ~4.1GB | Alternativa balanceada |
| **codellama:7b** | ~3.8GB | Especializado en código |

### 3.3 Descargar Modelos

```bash
# Modelo recomendado por defecto
ollama pull llama3.2:3b

# Ver modelos instalados
ollama list
```

---

## 4. Optimización para OPENCLAW

### 4.1 Modelfile Personalizado

```bash
cat > ~/Modelfile.openclaw << 'EOF'
FROM llama3.2:3b

# Parámetros optimizados para VPS
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER num_ctx 4096
PARAMETER num_predict 2048
PARAMETER repeat_penalty 1.1
PARAMETER stop "<|eot_id|>"
PARAMETER stop "<|end_of_text|>"

# System prompt para OPENCLAW
SYSTEM """
Eres un agente especializado del sistema OPENCLAW.
Tu función es asistir de manera precisa, concisa y profesional.

Directrices:
- Responde de forma clara y directa
- Cuando ejecutes comandos, verifica antes de actuar
- Si no estás seguro, solicita aclaración
- Documenta tus decisiones
- Prioriza la seguridad y precisión

Formato de respuestas:
- Usa markdown cuando sea apropiado
- Estructura respuestas largas en secciones
- Incluye ejemplos cuando ayude a la comprensión
"""
EOF

# Crear modelo personalizado
ollama create openclaw-llama32 -f ~/Modelfile.openclaw
```

### 4.2 Configuración de Contexto

```bash
# Aumentar contexto si hay RAM disponible
cat > ~/Modelfile.openclaw-8k << 'EOF'
FROM llama3.2:3b
PARAMETER num_ctx 8192
PARAMETER num_predict 4096
SYSTEM """
Eres un agente OPENCLAW con contexto extendido.
Puedes procesar documentos más largos y mantener conversaciones más extensas.
"""
EOF

ollama create openclaw-llama32-8k -f ~/Modelfile.openclaw-8k
```

---

## 5. Gestión de Modelos

### 5.1 Comandos Útiles

```bash
# Listar modelos
ollama list

# Ver información de modelo
ollama show llama3.2:3b

# Eliminar modelo
ollama rm modelo:no-usado

# Actualizar modelo
ollama pull llama3.2:3b

# Copiar modelo
ollama cp llama3.2:3b mi-modelo-personalizado
```

### 5.2 Uso de Memoria

```bash
# Ver procesos de Ollama
ollama ps

# Ejemplo output:
# NAME       ID          SIZE    PROCESSOR    UNTIL
# llama3.2   abc123...   2.1 GB  100% GPU     5 minutes from now
```

---

## 6. API Endpoints

### 6.1 Generate (Sin Stream)

```bash
curl http://127.0.0.1:11434/api/generate -d '{
  "model": "openclaw-llama32",
  "prompt": "¿Qué es OPENCLAW?",
  "stream": false
}'
```

### 6.2 Chat

```bash
curl http://127.0.0.1:11434/api/chat -d '{
  "model": "openclaw-llama32",
  "messages": [
    {"role": "system", "content": "Eres un asistente OPENCLAW"},
    {"role": "user", "content": "Hola"}
  ],
  "stream": false
}'
```

### 6.3 Embeddings

```bash
curl http://127.0.0.1:11434/api/embeddings -d '{
  "model": "nomic-embed-text",
  "prompt": "Texto a convertir en embedding"
}'
```

---

## 7. Integración con OpenClaw

### 7.1 Configuración providers.json

```json
{
  "providers": {
    "ollama": {
      "name": "ollama",
      "baseUrl": "http://127.0.0.1:11434",
      "models": {
        "openclaw-llama32": {
          "enabled": true,
          "contextWindow": 4096,
          "maxOutput": 2048,
          "temperature": 0.7
        }
      },
      "timeout": 60000
    }
  }
}
```

### 7.2 Variables de Entorno

```bash
# En ~/.openclaw/config/.env
OLLAMA_HOST=127.0.0.1:11434
```

---

## 8. Troubleshooting

### 8.1 Ollama No Inicia

```bash
# Verificar estado
sudo systemctl status ollama

# Ver logs
journalctl -u ollama -n 50

# Reiniciar
sudo systemctl restart ollama
```

### 8.2 Error de Memoria

```bash
# Verificar memoria disponible
free -h

# Si hay poca RAM, usar modelo más pequeño
ollama pull llama3.2:1b

# O crear swap
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### 8.3 Modelo No Carga

```bash
# Verificar espacio en disco
df -h

# Verificar integridad del modelo
ollama pull llama3.2:3b --insecure

# Eliminar y volver a descargar
ollama rm llama3.2:3b
ollama pull llama3.2:3b
```

---

## 9. Monitoreo

### 9.1 Métricas Básicas

```bash
# Uso de recursos por Ollama
ps aux | grep ollama

# Memoria usada por modelos cargados
ollama ps

# Tamaño de modelos
ollama list
```

### 9.2 Logs

```bash
# Logs del servicio
journalctl -u ollama -f

# Logs de aplicación
tail -f ~/.openclaw/logs/worker-*.log | grep ollama
```

---

**Documento:** Anexo B - Configuración Ollama
**Relacionado:** [A-HOJA-RUTA-UBUNTU-24.04](./A-HOJA-RUTA-UBUNTU-24.04.md)
