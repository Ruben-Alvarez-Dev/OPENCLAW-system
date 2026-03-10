# Anexo C: Endurecimiento SSH

**ID:** DOC-ANX-SSH-001
**Propósito:** Configuración de seguridad SSH avanzada para OPENCLAW-system

---

## 1. Configuración Base

### 1.1 Archivo de Configuración

```bash
sudo nano /etc/ssh/sshd_config
```

### 1.2 Configuración Recomendada

```ssh
# === PUERTO Y BINDING ===
Port 2222                          # Puerto no estándar
AddressFamily inet                 # Solo IPv4
ListenAddress 0.0.0.0              # O específicar IP

# === AUTENTICACIÓN ===
PermitRootLogin no                 # NUNCA permitir root
PasswordAuthentication no          # Solo claves
PubkeyAuthentication yes           # Claves públicas habilitadas
PermitEmptyPasswords no            # Sin passwords vacíos
MaxAuthTries 3                     # Máximo 3 intentos
MaxSessions 5                      # Máximo 5 sesiones

# === USUARIOS PERMITIDOS ===
AllowUsers openclaw                # Solo usuarios listados

# === CRIPTOGRAFÍA ===
# Solo algoritmos seguros
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# === CLAVES DE HOST ===
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key

# === TIMEOUTS ===
LoginGraceTime 60                  # 60 segundos para login
ClientAliveInterval 300            # Check cada 5 minutos
ClientAliveCountMax 2              # 2 fallos = desconectar

# === DESHABILITAR INNECESARIO ===
X11Forwarding no                   # Sin X11
AllowAgentForwarding no            # Sin agent forwarding
AllowTcpForwarding no              # Sin TCP forwarding
PermitTunnel no                    # Sin túneles
PermitUserEnvironment no           # Sin env de usuario

# === LOGGING ===
SyslogFacility AUTH
LogLevel VERBOSE

# === MÉTODOS LEGADOS ===
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
UsePAM yes                         # PAM para accounting
```

---

## 2. Claves SSH

### 2.1 Generar Claves Seguras (Cliente)

```bash
# ED25519 (recomendado)
ssh-keygen -t ed25519 -C "openclaw@vps" -f ~/.ssh/openclaw_vps

# RSA 4096 (alternativa)
ssh-keygen -t rsa -b 4096 -C "openclaw@vps" -f ~/.ssh/openclaw_vps_rsa
```

### 2.2 Configuración del Cliente

```bash
cat >> ~/.ssh/config << 'EOF'
# OPENCLAW VPS
Host openclaw-vps
    HostName TU_IP_VPS
    Port 2222
    User openclaw
    IdentityFile ~/.ssh/openclaw_vps
    ServerAliveInterval 60
    ServerAliveCountMax 3
    Compression yes
EOF
```

### 2.3 Copiar Clave al Servidor

```bash
ssh-copy-id -i ~/.ssh/openclaw_vps.pub -p 2222 openclaw@TU_IP_VPS
```

---

## 3. Autenticación de Dos Factores (2FA)

### 3.1 Instalar OATH-TOTP

```bash
sudo apt install -y libpam-google-authenticator
```

### 3.2 Configurar para Usuario

```bash
# Como usuario openclaw
google-authenticator

# Responder:
# - Make tokens time-based? y
# - Update .google_authenticator file? y
# - Disallow multiple uses? y
# - Increase time skew? n (o y si hay problemas)
# - Rate limiting? y
```

### 3.3 Configurar PAM

```bash
sudo nano /etc/pam.d/sshd
```

Añadir al principio:
```
# Requerir 2FA
auth required pam_google_authenticator.so nullok
```

### 3.4 Configurar SSHD

```bash
sudo nano /etc/ssh/sshd_config
```

Asegurar:
```ssh
ChallengeResponseAuthentication yes
KbdInteractiveAuthentication yes
UsePAM yes

# Método de autenticación
AuthenticationMethods publickey,keyboard-interactive
```

### 3.5 Reiniciar SSH

```bash
sudo systemctl restart sshd
```

**IMPORTANTE:** Probar en nueva terminal antes de cerrar sesión actual.

---

## 4. Fail2Ban para SSH

### 4.1 Configuración

```bash
sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
bantime = 24h
findtime = 10m
maxretry = 3
ignoreip = 127.0.0.1/8 TU_IP_LOCAL

[sshd]
enabled = true
port = 2222
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 168h                    # 1 semana
findtime = 1h
action = %(action_mwl)s
EOF

sudo systemctl restart fail2ban
```

### 4.2 Comandos Útiles

```bash
# Ver estado
sudo fail2ban-client status sshd

# Desbanear IP
sudo fail2ban-client set sshd unbanip IP_ADDRESS

# Ver logs
sudo tail -f /var/log/fail2ban.log
```

---

## 5. Banner y Avisos

### 5.1 Banner Pre-Login

```bash
sudo tee /etc/ssh/banner > /dev/null << 'EOF'

╔══════════════════════════════════════════════════════════════╗
║                    OPENCLAW-system                           ║
║                                                              ║
║  ACCESO AUTORIZADO SOLAMENTE                                 ║
║  Todas las actividades son monitoreadas y registradas.       ║
║  El acceso no autorizado está prohibido.                     ║
╚══════════════════════════════════════════════════════════════╝

EOF
```

### 5.2 Configurar en sshd_config

```bash
echo "Banner /etc/ssh/banner" | sudo tee -a /etc/ssh/sshd_config
```

### 5.3 Mensaje Post-Login (motd)

```bash
sudo tee /etc/motd > /dev/null << 'EOF'
Bienvenido a OPENCLAW-system
Recuerda:
- Usa sudo solo cuando sea necesario
- Revisa los logs antes de hacer cambios
- Documenta todas las modificaciones
EOF
```

---

## 6. Auditoría SSH

### 6.1 Logs de Autenticación

```bash
# Ver intentos de login
sudo grep "Failed password" /var/log/auth.log

# Ver logins exitosos
sudo grep "Accepted password\|Accepted publickey" /var/log/auth.log

# Ver usuarios activos
who
```

### 6.2 Verificar Configuración

```bash
# Verificar sintaxis
sudo sshd -t

# Ver configuración efectiva
sudo sshd -T
```

### 6.3 Test de Seguridad

```bash
# Desde otra máquina
nmap -p 2222 --script ssh-auth-methods TU_IP_VPS
nmap -p 2222 --script ssh-hostkey TU_IP_VPS
```

---

## 7. Hardening Adicional

### 7.1 Deshabilitar Usuarios Innecesarios

```bash
# Verificar usuarios con shell
cat /etc/passwd | grep -E "/bin/bash|/bin/sh"

# Bloquear usuario si es necesario
sudo usermod -L usuario_a_bloquear
sudo usermod -s /usr/sbin/nologin usuario_a_bloquear
```

### 7.2 Limitar Conexiones por IP

```bash
# En /etc/hosts.allow
echo "sshd: 127.0.0.1, TU_IP_LOCAL" | sudo tee -a /etc/hosts.allow

# En /etc/hosts.deny (opcional, muy restrictivo)
echo "sshd: ALL" | sudo tee -a /etc/hosts.deny
```

### 7.3 Timeout de Sesión Idle

```bash
# En ~/.bashrc del usuario openclaw
echo 'TMOUT=1800' >> ~/.bashrc  # 30 minutos
source ~/.bashrc
```

---

## 8. Checklist de Seguridad SSH

| Item | Comando de Verificación |
|------|------------------------|
| Puerto no estándar | `grep Port /etc/ssh/sshd_config` |
| Root login deshabilitado | `grep PermitRootLogin /etc/ssh/sshd_config` |
| Solo claves | `grep PasswordAuthentication /etc/ssh/sshd_config` |
| Usuarios limitados | `grep AllowUsers /etc/ssh/sshd_config` |
| Fail2Ban activo | `sudo fail2ban-client status sshd` |
| 2FA configurado | `ls -la ~/.google_authenticator` |
| Banner configurado | `cat /etc/ssh/banner` |

---

**Documento:** Anexo C - Endurecimiento SSH
**Relacionado:** [A-HOJA-RUTA-UBUNTU-24.04](./A-HOJA-RUTA-UBUNTU-24.04.md), [D-AUDITORIA-SEGURIDAD](./D-AUDITORIA-SEGURIDAD.md)
