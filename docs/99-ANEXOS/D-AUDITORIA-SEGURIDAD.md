# Anexo D: Auditoría de Seguridad

**ID:** DOC-ANX-AUD-001
**Propósito:** Checklist y procedimientos de auditoría para OPENCLAW-system

---

## 1. Checklist de Seguridad Inicial

### 1.1 Sistema Operativo

```bash
#!/bin/bash
# Ejecutar como root o con sudo

echo "=== AUDITORÍA DE SEGURIDAD OPENCLAW ==="
echo "Fecha: $(date)"
echo ""

echo "### 1. USUARIO ROOT ###"
echo "Root login permitido: $(grep '^PermitRootLogin' /etc/ssh/sshd_config | awk '{print $2}')"
echo "Usuarios con UID 0: $(awk -F: '$3 == 0 {print $1}' /etc/passwd)"
echo ""

echo "### 2. USUARIOS ###"
echo "Usuarios con shell: $(cat /etc/passwd | grep -E '/bin/bash|/bin/sh' | cut -d: -f1)"
echo "Usuarios sudo: $(getent group sudo | cut -d: -f4)"
echo ""

echo "### 3. SSH ###"
echo "Puerto SSH: $(grep '^Port' /etc/ssh/sshd_config | awk '{print $2}')"
echo "Password auth: $(grep '^PasswordAuthentication' /etc/ssh/sshd_config | awk '{print $2}')"
echo "Pubkey auth: $(grep '^PubkeyAuthentication' /etc/ssh/sshd_config | awk '{print $2}')"
echo ""

echo "### 4. FIREWALL ###"
echo "UFW status: $(sudo ufw status | head -1)"
echo ""

echo "### 5. FAIL2BAN ###"
echo "Fail2ban status: $(sudo systemctl is-active fail2ban)"
sudo fail2ban-client status sshd 2>/dev/null || echo "Jail SSH no configurado"
echo ""

echo "### 6. SERVICIOS ###"
echo "Servicios escuchando:"
ss -tlnp | grep LISTEN
echo ""

echo "### 7. PUERTOS EXPUESTOS ###"
echo "Conexiones externas:"
ss -tlnp | grep -v "127.0.0.1"
echo ""

echo "### 8. DOCKER ###"
docker --version 2>/dev/null || echo "Docker no instalado"
docker ps 2>/dev/null | head -5 || true
echo ""

echo "### 9. OLLAMA ###"
curl -s http://127.0.0.1:11434/api/version || echo "Ollama no responde"
ss -tlnp | grep 11434
echo ""

echo "### 10. PM2 ###"
pm2 list 2>/dev/null || echo "PM2 no disponible"
echo ""

echo "### 11. ACTUALIZACIONES ###"
apt list --upgradable 2>/dev/null | head -10
echo ""

echo "### 12. PERMISOS CRÍTICOS ###"
ls -la ~/.openclaw/config/.env 2>/dev/null || echo ".env no encontrado"
ls -la ~/.ssh/authorized_keys 2>/dev/null || echo "authorized_keys no encontrado"
```

### 1.2 Ejecutar Auditoría

```bash
chmod +x security-audit.sh
./security-audit.sh > audit-$(date +%Y%m%d).txt
```

---

## 2. Verificaciones Periódicas

### 2.1 Diarias

| Verificación | Comando |
|--------------|---------|
| Logs de autenticación | `grep -E "Failed|Accepted" /var/log/auth.log \| tail -20` |
| Estado de servicios | `pm2 status && docker ps` |
| Uso de disco | `df -h` |
| Memoria | `free -h` |
| Carga del sistema | `uptime` |

### 2.2 Semanales

| Verificación | Comando |
|--------------|---------|
| Actualizaciones disponibles | `apt list --upgradable` |
| Logs de Fail2Ban | `sudo cat /var/log/fail2ban.log \| tail -50` |
| Puertos abiertos | `sudo ss -tlnp` |
| Procesos sospechosos | `ps aux --sort=-%mem \| head -10` |

### 2.3 Mensuales

| Verificación | Comando |
|--------------|---------|
| Usuarios del sistema | `cat /etc/passwd` |
| Claves SSH autorizadas | `cat ~/.ssh/authorized_keys` |
| Cron jobs | `crontab -l` |
| Backup verification | `ls -la /backup/` |

---

## 3. Auditoría de Red

### 3.1 Puertos Abiertos

```bash
# Puertos TCP en escucha
ss -tlnp

# Puertos UDP en escucha
ss -ulnp

# Conexiones activas
ss -tan | grep ESTAB
```

### 3.2 Servicios Expuestos

```bash
# Verificar qué escucha en 0.0.0.0
ss -tlnp | grep "0.0.0.0"

# Verificar que servicios críticos solo en localhost
for port in 11434 18789; do
    echo "Puerto $port:"
    ss -tlnp | grep ":$port"
done
```

### 3.3 Firewall Rules

```bash
# Reglas UFW
sudo ufw status numbered

# Reglas iptables (si aplica)
sudo iptables -L -n -v
```

---

## 4. Auditoría de Archivos

### 4.1 Archivos Sensibles

```bash
#!/bin/bash
echo "=== ARCHIVOS SENSIBLES ==="

# Verificar permisos de archivos críticos
files=(
    "/etc/shadow"
    "/etc/passwd"
    "/etc/ssh/sshd_config"
    "/home/openclaw/.ssh/authorized_keys"
    "/home/openclaw/.openclaw/config/.env"
)

for f in "${files[@]}"; do
    if [ -f "$f" ]; then
        perms=$(stat -c "%a %U:%G %n" "$f")
        echo "$perms"
    fi
done
```

### 4.2 Búsqueda de Secretos

```bash
# Buscar posibles secretos en código
grep -r "password\s*=" ~/.openclaw/ 2>/dev/null || echo "OK"
grep -r "api_key\s*=" ~/.openclaw/ 2>/dev/null || echo "OK"
grep -r "token\s*=" ~/.openclaw/ 2>/dev/null || echo "OK"
grep -r "secret\s*=" ~/.openclaw/ 2>/dev/null || echo "OK"

# Verificar que no hay claves en repositorios
find ~/projects -name ".env" -o -name "*.pem" -o -name "*key*" 2>/dev/null
```

---

## 5. Auditoría de Logs

### 5.1 Logs del Sistema

```bash
# Últimos logins
last -n 20

# Intentos fallidos
sudo grep "Failed password" /var/log/auth.log | tail -20

# Logs de sudo
sudo grep "sudo:" /var/log/auth.log | tail -20
```

### 5.2 Logs de Aplicación

```bash
# Logs de PM2
pm2 logs --lines 50 --nostream

# Logs de errores
tail -50 ~/.openclaw/logs/*-error.log

# Buscar errores
grep -r "error\|ERROR\|fail\|FAIL" ~/.openclaw/logs/ | tail -20
```

---

## 6. Verificación de Integridad

### 6.1 Checksums de Configuración

```bash
#!/bin/bash
# Crear checksums de archivos críticos

CRITICAL_FILES=(
    "/etc/ssh/sshd_config"
    "/etc/fail2ban/jail.local"
    "/home/openclaw/.openclaw/config/.env"
    "/home/openclaw/projects/openclaw/ecosystem.config.js"
)

echo "=== CHECKSUMS ==="
for f in "${CRITICAL_FILES[@]}"; do
    if [ -f "$f" ]; then
        echo "$(sha256sum "$f")"
    fi
done
```

### 6.2 Verificar Cambios

```bash
# Comparar con baseline
sha256sum -c checksums.txt
```

---

## 7. Reporte de Auditoría

### 7.1 Template

```markdown
# Reporte de Auditoría OPENCLAW-system

**Fecha:** YYYY-MM-DD HH:MM
**Auditor:** [Nombre]
**Servidor:** [Hostname/IP]

## Resumen Ejecutivo

- **Estado General:** [OK/WARNING/CRITICAL]
- **Hallazgos Críticos:** [Número]
- **Recomendaciones:** [Número]

## Hallazgos

### Críticos
1. [Descripción]
2. [Descripción]

### Advertencias
1. [Descripción]

### Información
1. [Descripción]

## Estado de Servicios

| Servicio | Estado | Puerto | Bind |
|----------|--------|--------|------|
| SSH | ✓ | 2222 | 0.0.0.0 |
| Ollama | ✓ | 11434 | 127.0.0.1 |
| Gateway | ✓ | 18789 | 127.0.0.1 |
| PM2 | ✓ | - | - |

## Recomendaciones

1. [Recomendación]
2. [Recomendación]

## Próxima Auditoría

Fecha sugerida: [YYYY-MM-DD]
```

---

## 8. Automatización

### 8.1 Cron Job

```bash
# Añadir a crontab
crontab -e

# Auditoría diaria a las 6:00 AM
0 6 * * * /home/openclaw/scripts/security-audit.sh > /home/openclaw/logs/audit-$(date +\%Y\%m\%d).log 2>&1
```

### 8.2 Alertas

```bash
# Enviar alerta si hay hallazgos críticos
if grep -q "CRITICAL" /home/openclaw/logs/audit-*.log; then
    # Enviar notificación (email, Telegram, etc.)
    echo "Alerta de seguridad detectada"
fi
```

---

**Documento:** Anexo D - Auditoría de Seguridad
**Relacionado:** [C-ENDURECIMIENTO-SSH](./C-ENDURECIMIENTO-SSH.md), [F-REMEDIACION-CVE](./F-REMEDIACION-CVE.md)
