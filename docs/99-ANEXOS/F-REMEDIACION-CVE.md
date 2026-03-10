# Anexo F: Remediación de CVEs

**ID:** DOC-ANX-CVE-001
**Propósito:** Parcheo de vulnerabilidades conocidas en OPENCLAW-system

---

## 1. CVEs Críticos (2024-2026)

### 1.1 Kernel Ubuntu/Debian

| CVE | Severidad | Descripción | Verificación |
|-----|-----------|-------------|--------------|
| CVE-2025-37899 | CRÍTICA | Privilege escalation | `uname -r` |
| CVE-2025-22037 | CRÍTICA | Use-after-free | `uname -r` |

**Remediación:**
```bash
# Verificar versión actual
uname -r

# Actualizar kernel
sudo apt update
sudo apt install --install-recommends linux-generic

# Reiniciar
sudo reboot

# Verificar nueva versión
uname -r
```

### 1.2 Docker runc

| CVE | Severidad | CVSS | Descripción |
|-----|-----------|------|-------------|
| CVE-2024-21626 | CRÍTICA | 8.6 | Container escape via WORKDIR |

**Remediación:**
```bash
# Verificar versión de runc
runc --version

# Actualizar a versión >= 1.1.12
sudo apt update
sudo apt install -y runc

# Verificar
runc --version
# Debe ser >= 1.1.12

# Reiniciar Docker
sudo systemctl restart docker
```

### 1.3 PM2

| CVE | Severidad | Descripción |
|-----|-----------|-------------|
| PM2 < 5.4.3 | ALTA | Command Injection via ecosystem.config.js |

**Remediación:**
```bash
# Verificar versión
pm2 --version

# Actualizar a última versión
npm update -g pm2

# Verificar >= 5.4.3
pm2 --version

# Actualizar procesos
pm2 update
```

---

## 2. LangChain CVEs (Ecosistema)

### 2.1 Vulnerabilidades Conocidas

| CVE | Severidad | Componente | Descripción |
|-----|-----------|------------|-------------|
| CVE-2024-27448 | ALTA | SQLDatabaseChain | RCE via SQL injection |
| CVE-2024-21513 | ALTA | PyPDFLoader | Arbitrary file read |
| CVE-2023-44468 | MEDIA | WebBaseLoader | SSRF vulnerability |
| CVE-2023-46229 | MEDIA | VectorStore | Information disclosure |

### 2.2 Mitigaciones

```bash
# Si se usa Python/LangChain
pip list | grep langchain

# Actualizar a últimas versiones
pip install --upgrade langchain langchain-core langchain-community

# Verificar versiones
pip show langchain
```

**Mitigaciones en OpenClaw:**
- Validar inputs antes de pasar a LangChain
- Usar sandbox para ejecución de código
- Limitar acceso a filesystem

---

## 3. CVEs de Node.js

### 3.1 Verificar Vulnerabilidades

```bash
# Auditar dependencias
cd ~/projects/openclaw
npm audit

# Ver detalles
npm audit --json

# Corregir automáticamente
npm audit fix

# Forzar corrección (puede romper compatibilidad)
npm audit fix --force
```

### 3.2 Actualizar Node.js

```bash
# Verificar versión actual
node --version

# Actualizar a última LTS
nvm install --lts
nvm use --lts
nvm alias default lts/*

# Verificar
node --version
```

---

## 4. Ollama CVEs

### 4.1 Exposición de Red (No CVE, pero crítico)

**Problema:** Ollama por defecto escucha en 0.0.0.0:11434

**Verificación:**
```bash
ss -tlnp | grep 11434
```

**Remediación:**
```bash
# Configurar bind a localhost
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
# Debe mostrar: 127.0.0.1:11434, NO 0.0.0.0:11434
```

### 4.2 Actualizar Ollama

```bash
# Verificar versión
ollama --version

# Actualizar
curl -fsSL https://ollama.com/install.sh | sh

# Verificar
ollama --version
```

---

## 5. Docker CVEs

### 5.1 Hardening de Contenedores

**Configuración segura en OpenClaw:**
```json
{
  "sandbox": {
    "networkMode": "none",
    "memory": "512m",
    "cpus": 1,
    "user": "nobody",
    "readOnlyRootFilesystem": true,
    "capDrop": ["ALL"],
    "securityOpt": ["no-new-privileges"]
  }
}
```

### 5.2 Verificar Configuración

```bash
# Verificar que no hay contenedores privilegiados
docker ps --format '{{.Names}} {{.HostConfig.Privileged}}'

# Verificar capabilities
docker inspect --format '{{.HostConfig.CapDrop}}' $(docker ps -q)

# Auditar configuración Docker
docker info | grep -E "Security|Cgroup"
```

---

## 6. Checklist de Remediación

### 6.1 Verificación Post-Parcheo

```bash
#!/bin/bash
echo "=== VERIFICACIÓN DE CVEs ==="

echo "1. Kernel:"
uname -r

echo ""
echo "2. Docker:"
docker --version
runc --version

echo ""
echo "3. PM2:"
pm2 --version

echo ""
echo "4. Node.js:"
node --version

echo ""
echo "5. Ollama:"
ollama --version
ss -tlnp | grep 11434

echo ""
echo "6. Dependencias npm:"
cd ~/projects/openclaw
npm audit --audit-level=high

echo ""
echo "7. Servicios críticos solo en localhost:"
ss -tlnp | grep -E "11434|18789"
```

### 6.2 Programar Actualizaciones

```bash
# Actualizaciones de seguridad automáticas
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Verificar configuración
cat /etc/apt/apt.conf.d/20auto-upgrades
```

---

## 7. Monitoreo de CVEs

### 7.1 Fuentes de Información

| Fuente | URL |
|--------|-----|
| Ubuntu Security | https://ubuntu.com/security/notices |
| Docker Security | https://docs.docker.com/security/ |
| NPM Security | https://www.npmjs.com/advisories |
| NIST NVD | https://nvd.nist.gov/ |
| Ollama Releases | https://github.com/ollama/ollama/releases |

### 7.2 Suscripciones Recomendadas

- Ubuntu Security Announcements
- Docker Security Mailing List
- Node.js Security Releases
- OpenClaw GitHub Releases

---

## 8. Respuesta a Incidentes

### 8.1 Si se Detecta Vulnerabilidad

1. **Aislar:** Detener servicios afectados
2. **Evaluar:** Determinar impacto y exposición
3. **Parchear:** Aplicar actualización o workaround
4. **Verificar:** Confirmar remediación exitosa
5. **Documentar:** Registrar incidente y solución

### 8.2 Comandos de Emergencia

```bash
# Detener todos los servicios
pm2 stop all
sudo systemctl stop ollama

# Aplicar actualizaciones de seguridad
sudo apt update && sudo apt upgrade -y --with-new-pkgs

# Reiniciar servicios
sudo systemctl start ollama
pm2 start all

# Verificar
pm2 status
curl http://127.0.0.1:11434/api/version
```

---

**Documento:** Anexo F - Remediación de CVEs
**Relacionado:** [D-AUDITORIA-SEGURIDAD](./D-AUDITORIA-SEGURIDAD.md), [11-SEGURIDAD](../11-SEGURIDAD/)
