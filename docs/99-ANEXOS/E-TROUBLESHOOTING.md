# Anexo E: Troubleshooting

**ID:** DOC-ANX-TRO-001
**Propósito:** Guía de diagnóstico y resolución de problemas comunes

---

## 1. Problemas de Conexión

### 1.1 SSH No Conecta

**Síntomas:**
```
ssh: connect to host X.X.X.X port 2222: Connection refused
ssh: connect to host X.X.X.X port 2222: Connection timed out
```

**Diagnóstico:**
```bash
# Verificar que SSH está corriendo
sudo systemctl status sshd

# Verificar puerto
ss -tlnp | grep 2222

# Verificar firewall
sudo ufw status | grep 2222

# Verificar logs
sudo tail -20 /var/log/auth.log
```

**Soluciones:**
```bash
# Reiniciar SSH
sudo systemctl restart sshd

# Abrir puerto en firewall
sudo ufw allow 2222/tcp

# Verificar configuración
sudo sshd -t
```

### 1.2 Clave SSH Rechazada

**Síntomas:**
```
Permission denied (publickey)
```

**Diagnóstico:**
```bash
# Verificar permisos
ls -la ~/.ssh/
# Debe ser 700 para directorio, 600 para archivos

# Verificar authorized_keys
cat ~/.ssh/authorized_keys

# Probar con verbose
ssh -vvv -p 2222 openclaw@IP
```

**Soluciones:**
```bash
# Corregir permisos
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Añadir clave
ssh-copy-id -i ~/.ssh/mi_clave.pub -p 2222 openclaw@IP
```

---

## 2. Problemas de Ollama

### 2.1 Ollama No Responde

**Síntomas:**
```
curl: (7) Failed to connect to 127.0.0.1 port 11434
Error: connection refused
```

**Diagnóstico:**
```bash
# Estado del servicio
sudo systemctl status ollama

# Verificar proceso
ps aux | grep ollama

# Verificar puerto
ss -tlnp | grep 11434

# Ver logs
journalctl -u ollama -n 50
```

**Soluciones:**
```bash
# Reiniciar servicio
sudo systemctl restart ollama

# Verificar instalación
which ollama
ollama --version

# Reinstalar si es necesario
curl -fsSL https://ollama.com/install.sh | sh
```

### 2.2 Modelo No Carga

**Síntomas:**
```
Error: model "llama3.2:3b" not found
OOM (Out of Memory)
```

**Diagnóstico:**
```bash
# Verificar modelos
ollama list

# Verificar memoria
free -h

# Verificar espacio
df -h ~/.ollama
```

**Soluciones:**
```bash
# Descargar modelo
ollama pull llama3.2:3b

# Usar modelo más pequeño
ollama pull llama3.2:1b

# Crear swap si falta memoria
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### 2.3 Ollama Expuesto a Red

**Síntomas:**
```
ss muestra: 0.0.0.0:11434
```

**Solución:**
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
# Debe mostrar: 127.0.0.1:11434
```

---

## 3. Problemas de PM2

### 3.1 Procesos Caídos

**Síntomas:**
```
┌─────┬────────────────┬─────────┬─────────┐
│ id  │ name           │ status  │ cpu     │
├─────┼────────────────┼─────────┼─────────┤
│ 0   │ sis-gateway    │ errored │ 0%      │
```

**Diagnóstico:**
```bash
# Ver logs
pm2 logs sis-gateway --lines 50

# Ver descripción
pm2 describe sis-gateway

# Verificar archivos
ls -la ~/projects/openclaw/dist/cli/
```

**Soluciones:**
```bash
# Reiniciar proceso
pm2 restart sis-gateway

# Si persiste, reiniciar todo
pm2 restart all

# Verificar configuración
pm2 show sis-gateway
```

### 3.2 PM2 No Inicia al Arranque

**Diagnóstico:**
```bash
# Verificar startup
pm2 startup

# Verificar systemd
systemctl --user status pm2-openclaw
```

**Soluciones:**
```bash
# Regenerar startup
pm2 unstartup
pm2 startup systemd -u openclaw --hp /home/openclaw

# Guardar configuración
pm2 save
```

### 3.3 Memoria Insuficiente

**Síntomas:**
```
JavaScript heap out of memory
FATAL ERROR: Ineffective mark-compacts near heap limit
```

**Soluciones:**
```bash
# Aumentar límite en ecosystem.config.js
max_memory_restart: '1G'  # o más

# O con variable de entorno
NODE_OPTIONS="--max-old-space-size=4096" pm2 restart all
```

---

## 4. Problemas de Docker

### 4.1 Docker No Inicia

**Diagnóstico:**
```bash
# Estado del servicio
sudo systemctl status docker

# Versión
docker --version

# Permisos
groups | grep docker
```

**Soluciones:**
```bash
# Reiniciar Docker
sudo systemctl restart docker

# Añadir usuario a grupo
sudo usermod -aG docker openclaw
# Cerrar y volver a abrir sesión

# Verificar rootless
docker context ls
```

### 4.2 Contenedores No Acceden a Red

**Diagnóstico:**
```bash
# Verificar redes
docker network ls

# Inspeccionar red
docker network inspect none
```

**Soluciones:**
```bash
# Si se necesita red (NO recomendado para sandbox)
# Modificar networkMode en configuración
```

---

## 5. Problemas de Gateway

### 5.1 Gateway No Responde

**Síntomas:**
```
curl: (7) Failed to connect to 127.0.0.1 port 18789
```

**Diagnóstico:**
```bash
# Verificar proceso
pm2 status | grep gateway

# Verificar puerto
ss -tlnp | grep 18789

# Ver logs
pm2 logs sis-gateway --lines 50
```

**Soluciones:**
```bash
# Reiniciar
pm2 restart sis-gateway

# Verificar configuración
cat ~/.openclaw/config/.env | grep GATEWAY

# Verificar que el puerto no está en uso
sudo lsof -i :18789
```

### 5.2 Error de Token

**Síntomas:**
```
Authentication failed
Invalid token
```

**Soluciones:**
```bash
# Regenerar token
NEW_TOKEN=$(openssl rand -hex 24)
sed -i "s/^GATEWAY_TOKEN=.*/GATEWAY_TOKEN=$NEW_TOKEN/" ~/.openclaw/config/.env

# Reiniciar servicios
pm2 restart all
```

---

## 6. Problemas de Memoria

### 6.1 Sistema Lento

**Diagnóstico:**
```bash
# Memoria
free -h

# Swap
swapon --show

# Top procesos
top -o %MEM
```

**Soluciones:**
```bash
# Limpiar caché
sync && echo 3 | sudo tee /proc/sys/vm/drop_caches

# Añadir swap
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Añadir a fstab para persistencia
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 6.2 Disco Lleno

**Diagnóstico:**
```bash
# Espacio
df -h

# Directorios grandes
du -sh /* 2>/dev/null | sort -rh | head -10

# Archivos grandes
find / -type f -size +100M 2>/dev/null
```

**Soluciones:**
```bash
# Limpiar paquetes
sudo apt autoremove -y
sudo apt autoclean

# Limpiar logs antiguos
sudo journalctl --vacuum-time=7d

# Limpiar Docker
docker system prune -af

# Limpiar Ollama modelos no usados
ollama rm modelo:no-usado
```

---

## 7. Problemas de Rendimiento

### 7.1 Respuestas Lentas

**Diagnóstico:**
```bash
# Carga del sistema
uptime

# I/O wait
iostat -x 1 5

# Procesos
ps aux --sort=-%cpu | head -10
```

**Soluciones:**
```bash
# Reducir carga de Ollama
# Usar modelo más pequeño
ollama run llama3.2:1b

# Ajustar workers PM2
# En ecosystem.config.js, reducir instances si hay múltiples
```

---

## 8. Recuperación de Desastres

### 8.1 Sistema No Arranca

```bash
# Acceder via consola del proveedor VPS

# Verificar filesystem
sudo fsck -y /dev/vda1

# Verificar servicios críticos
sudo systemctl status sshd
sudo systemctl status docker

# Restaurar configuración
cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
sudo systemctl restart sshd
```

### 8.2 Restaurar desde Backup

```bash
# Restaurar configuración
tar -xzvf openclaw-config-YYYYMMDD.tar.gz -C ~/

# Restaurar datos
tar -xzvf openclaw-data-YYYYMMDD.tar.gz -C ~/

# Reiniciar servicios
pm2 restart all
```

---

## 9. Contacto y Escalado

### 9.1 Información a Recopilar

Antes de pedir ayuda, recopilar:

```bash
# Generar reporte
{
    echo "=== INFO SISTEMA ==="
    uname -a
    lsb_release -a
    echo ""
    echo "=== ESTADO SERVICIOS ==="
    pm2 status
    docker ps
    echo ""
    echo "=== MEMORIA ==="
    free -h
    echo ""
    echo "=== DISCO ==="
    df -h
    echo ""
    echo "=== RED ==="
    ss -tlnp
    echo ""
    echo "=== LOGS RECIENTES ==="
    pm2 logs --lines 20 --nostream
} > debug-report.txt
```

### 9.2 Logs Importantes

| Archivo | Contenido |
|---------|-----------|
| `/var/log/auth.log` | Autenticación SSH |
| `/var/log/syslog` | Sistema |
| `~/.openclaw/logs/*.log` | Aplicación |
| `journalctl -u ollama` | Ollama |
| `journalctl -u docker` | Docker |

---

**Documento:** Anexo E - Troubleshooting
**Relacionado:** [A-HOJA-RUTA-UBUNTU-24.04](./A-HOJA-RUTA-UBUNTU-24.04.md), [D-AUDITORIA-SEGURIDAD](./D-AUDITORIA-SEGURIDAD.md)
