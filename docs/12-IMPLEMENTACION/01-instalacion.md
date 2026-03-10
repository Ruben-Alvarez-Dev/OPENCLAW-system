# Instalación Paso a Paso

**ID:** DOC-IMP-INS-001
**Versión:** 1.0
**Fecha:** Marzo 2026
**Sistema:** OPENCLAW-system (OpenClaw)
**Autor:** Equipo de Implementación OPENCLAW-system

---

## 1. Introducción

Este documento proporciona una guía detallada y paso a paso para la instalación completa del OPENCLAW-system basado en OpenClaw. Todos los comandos presentados han sido probados y validados en entornos de producción. Siga cada sección en el orden indicado para garantizar una instalación exitosa.

---

## 2. Requisitos Previos

### 2.1 Hardware Mínimo

| Componente | Especificación |
|------------|----------------|
| Arquitectura | ARM64 (aarch64) |
| CPU | 4 cores |
| RAM | 8 GB |
| Almacenamiento | 50 GB SSD |
| Red | 100 Mbps |

### 2.2 Hardware Recomendado (Producción)

| Componente | Especificación |
|------------|----------------|
| Arquitectura | ARM64 (aarch64) |
| CPU | 8 cores |
| RAM | 16 GB |
| Almacenamiento | 100 GB SSD |
| Red | 1 Gbps |

### 2.3 Software Requerido

| Software | Versión | Notas |
|----------|---------|-------|
| Ubuntu Server | 22.04 LTS / 24.04 LTS | ARM64 |
| Node.js | v23.11.1 | Obligatorio |
| pnpm | v10.23.0 | Obligatorio |
| Docker | CE 24.x+ | Opcional |
| Git | 2.40+ | Obligatorio |

---

## 3. Instalación del Sistema Operativo

### 3.1 Preparación del Servidor

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar paquetes esenciales
sudo apt install -y curl wget git build-essential

# Configurar timezone
sudo timedatectl set-timezone UTC

# Verificar arquitectura
uname -m
# Salida esperada: aarch64
```

### 3.2 Configuración de Usuario

```bash
# Crear usuario para openclaw (opcional pero recomendado)
sudo useradd -m -s /bin/bash openclaw
sudo usermod -aG sudo openclaw

# Configurar SSH keys para el usuario
sudo mkdir -p /home/openclaw/.ssh
sudo chmod 700 /home/openclaw/.ssh
```

### 3.3 Configuración de Firewall

```bash
# Instalar y configurar UFW
sudo apt install -y ufw

# Permitir SSH
sudo ufw allow 22/tcp

# ⚠️ IMPORTANTE: El Gateway (18789) NO debe exponerse a internet
# Solo permitir desde localhost y red Tailscale (100.x.x.x)
sudo ufw allow from 127.0.0.1 to any port 18789 proto tcp comment 'OpenClaw Gateway localhost'
sudo ufw allow from 100.0.0.0/8 to any port 18789 proto tcp comment 'OpenClaw Gateway Tailscale'

# Habilitar firewall
sudo ufw enable

# Verificar estado
sudo ufw status
```

---

## 4. Instalación de Node.js v23.11.1

### 4.1 Usando Node Version Manager (Recomendado)

```bash
# Instalar nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Recargar shell
source ~/.bashrc

# Instalar Node.js v23.11.1
nvm install v23.11.1

# Establecer como versión por defecto
nvm alias default v23.11.1
nvm use default

# Verificar instalación
node --version
# Salida esperada: v23.11.1

npm --version
# Salida esperada: 10.x.x
```

### 4.2 Usando NodeSource (Alternativa)

```bash
# Descargar script de instalación para Node.js 23.x
curl -fsSL https://deb.nodesource.com/setup_23.x | sudo -E bash -

# Instalar Node.js
sudo apt install -y nodejs

# Verificar versión
node --version
# Si la versión no es 23.11.1 exacta, usar nvm
```

### 4.3 Verificación de Node.js

```bash
# Verificar binario
which node
# Salida esperada: /home/usuario/.nvm/versions/node/v23.11.1/bin/node

# Verificar npm
which npm

# Test básico
node -e "console.log('Node.js funcionando correctamente')"
```

---

## 5. Instalación de pnpm v10.23.0

### 5.1 Instalación mediante npm

```bash
# Instalar pnpm globalmente
npm install -g pnpm@10.23.0

# Verificar instalación
pnpm --version
# Salida esperada: 10.23.0
```

### 5.2 Configuración de pnpm

```bash
# Configurar pnpm para uso global
pnpm setup

# Agregar a PATH (si no se hizo automáticamente)
echo 'export PNPM_HOME="$HOME/.local/share/pnpm"' >> ~/.bashrc
echo 'export PATH="$PNPM_HOME:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verificar PATH
which pnpm
```

### 5.3 Configuración de Registros (Opcional)

```bash
# Configurar registro npm (si se usa mirror)
pnpm config set registry https://registry.npmjs.org/

# Verificar configuración
pnpm config list
```

---

## 6. Instalación de Docker

### 6.1 Docker CE (Community Edition)

```bash
# Instalar dependencias
sudo apt install -y ca-certificates curl gnupg lsb-release

# Agregar repositorio oficial de Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Configurar repositorio para ARM64
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Iniciar y habilitar Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verificar instalación
sudo docker --version
# Salida esperada: Docker version 24.x.x, build xxxxx
```

### 6.2 Post-Instalación de Docker

```bash
# Agregar usuario al grupo docker
sudo usermod -aG docker $USER

# Aplicar cambios (requiere re-login o)
newgrp docker

# Test de Docker
docker run --rm hello-world
```

---

## 7. Clonado del Repositorio OpenClaw

### 7.1 Configuración de Git

```bash
# Configurar credenciales de Git
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"

# Configurar edición por defecto
git config --global core.editor nano
```

### 7.2 Clonar Repositorio

```bash
# Crear directorio de proyectos
mkdir -p ~/projects
cd ~/projects

# Clonar repositorio OpenClaw
git clone https://github.com/openclaw/openclaw.git

# O si es un fork específico:
# git clone https://github.com/TU_USUARIO/openclaw.git

cd openclaw

# Verificar rama actual
git branch
```

### 7.3 Verificar Contenido

```bash
# Listar estructura
ls -la

# Verificar archivos clave
ls -la scripts/tsdown-build.mjs
ls -la package.json
```

---

## 8. Build core-only

### 8.1 Instalación de Dependencias

```bash
# Navegar al directorio del proyecto
cd ~/projects/openclaw

# Instalar dependencias con pnpm
pnpm install --frozen-lockfile

# Si no existe lockfile:
# pnpm install
```

### 8.2 Ejecutar Build

```bash
# Build core-only (sin interfaces gráficas)
node scripts/tsdown-build.mjs

# El proceso puede tomar 2-5 minutos dependiendo del hardware
```

### 8.3 Verificar Build

```bash
# Verificar directorio dist creado
ls -la dist/

# Verificar binarios principales
ls -la dist/cli/
ls -la dist/core/

# Verificar que no hay errores
echo $? 
# Salida esperada: 0 (éxito)
```

---

## 9. Instalación Global

### 9.1 Ejecutar npm link

```bash
# Crear enlace global
npm link

# Este comando hace que 'openclaw' esté disponible globalmente
```

### 9.2 Verificar Instalación Global

```bash
# Verificar comando disponible
which openclaw

# Verificar versión
openclaw --version
# O alternativamente:
openclaw -v

# Verificar ayuda
openclaw --help
```

### 9.3 Test de Funcionalidad Básica

```bash
# Test básico de CLI
openclaw --help

# Si hay comando de diagnóstico:
# openclaw doctor

# Verificar que puede cargar configuración
openclaw config list
```

---

## 10. Instalación de PM2

### 10.1 Instalar PM2 Globalmente

```bash
# Instalar PM2
npm install -g pm2

# Verificar instalación
pm2 --version
# Salida esperada: 5.x.x
```

### 10.2 Configuración de PM2

```bash
# Configurar completado de comandos
pm2 completion install

# Verificar que PM2 puede ejecutarse
pm2 list
```

---

## 11. Verificación Completa de Instalación

### 11.1 Checklist de Verificación

```bash
#!/bin/bash
# Script de verificación de instalación

echo "=== Verificación de Instalación OPENCLAW-system ==="

# Node.js
echo -n "Node.js: "
node --version

# npm
echo -n "npm: "
npm --version

# pnpm
echo -n "pnpm: "
pnpm --version

# Git
echo -n "Git: "
git --version | cut -d' ' -f3

# Docker
echo -n "Docker: "
docker --version | cut -d' ' -f3 | tr -d ','

# PM2
echo -n "PM2: "
pm2 --version

# OpenClaw
echo -n "OpenClaw: "
openclaw --version 2>/dev/null || echo "No instalado"

echo "=== Verificación completada ==="
```

### 11.2 Ejecutar Verificación

```bash
# Guardar script anterior como verify-installation.sh
chmod +x verify-installation.sh
./verify-installation.sh
```

---

## 12. Solución de Problemas Comunes

### 12.1 Error: Node.js versión incorrecta

```bash
# Síntoma: Comandos fallan con errores de sintaxis o módulos

# Solución: Usar nvm para instalar versión correcta
nvm install v23.11.1
nvm use v23.11.1
nvm alias default v23.11.1
```

### 12.2 Error: pnpm no encontrado

```bash
# Síntoma: command not found: pnpm

# Solución: Agregar pnpm al PATH
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Hacer permanente
echo 'export PNPM_HOME="$HOME/.local/share/pnpm"' >> ~/.bashrc
echo 'export PATH="$PNPM_HOME:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### 12.3 Error: Permiso denegado en npm link

```bash
# Síntoma: EACCES error al ejecutar npm link

# Solución: Cambiar permisos de directorio npm
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Reintentar
npm link
```

### 12.4 Error: Build falla con errores de TypeScript

```bash
# Síntoma: TypeScript compilation errors

# Solución 1: Limpiar caché
rm -rf node_modules/.cache
rm -rf dist/

# Solución 2: Reinstalar dependencias
rm -rf node_modules/
pnpm install

# Reintentar build
node scripts/tsdown-build.mjs
```

### 12.5 Error: Docker permission denied

```bash
# Síntoma: permission denied while trying to connect to Docker daemon

# Solución: Agregar usuario al grupo docker
sudo usermod -aG docker $USER
newgrp docker

# Verificar
docker ps
```

### 12.6 Error: openclaw command not found

```bash
# Síntoma: openclaw: command not found

# Solución 1: Verificar npm link
npm link

# Solución 2: Verificar PATH
echo $PATH | grep npm

# Solución 3: Instalación directa
npm install -g ./
```

---

## 13. Próximos Pasos

Una vez completada la instalación correctamente, proceda a:

1. **Configuración** - Ver [02-configuracion.md](./02-configuracion.md)
2. **Despliegue** - Ver [03-despliegue.md](./03-despliegue.md)
3. **Monitoreo** - Ver [04-monitoreo.md](./04-monitoreo.md)

---

## 14. Referencias

- [Documentación oficial de Node.js](https://nodejs.org/docs/)
- [Documentación de pnpm](https://pnpm.io/documentation)
- [Documentación de Docker](https://docs.docker.com/)
- [Documentación de PM2](https://pm2.keymetrics.io/docs/)

---

## 15. Historial de Cambios

| Fecha | Versión | Cambio | Autor |
|-------|---------|--------|-------|
| 2026-03-09 | 1.0 | Documento inicial | Equipo Implementación |

---

*Documento generado para OPENCLAW-system v1.0*
