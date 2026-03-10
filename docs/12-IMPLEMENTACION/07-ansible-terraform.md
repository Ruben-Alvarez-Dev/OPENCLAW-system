# Automatización con Ansible y Terraform

**ID:** DOC-IMP-IAC-001
**Versión:** 1.0
**Fecha:** 2026-03-10
**Estado:** Infraestructura como Código

---

## Resumen

Este documento proporciona playbooks de Ansible y módulos de Terraform para automatizar el despliegue de OPENCLAW-system.

---

## 1. Ansible

### 1.1 Estructura de Directorios

```
ansible/
├── inventory/
│   ├── production.yml
│   └── staging.yml
├── group_vars/
│   └── all.yml
├── roles/
│   ├── openclaw-common/
│   ├── openclaw-nodejs/
│   ├── openclaw-ollama/
│   ├── openclaw-gateway/
│   └── openclaw-agents/
├── playbooks/
│   ├── site.yml
│   ├── install.yml
│   └── upgrade.yml
├── templates/
│   ├── env.j2
│   └── ecosystem.config.js.j2
└── ansible.cfg
```

### 1.2 Inventory

```yaml
# inventory/production.yml
---
all:
  children:
    openclaw_servers:
      hosts:
        openclaw-prod-01:
          ansible_host: 192.168.1.100
          ansible_user: openclaw
          ansible_ssh_private_key_file: ~/.ssh/openclaw_prod
        openclaw-prod-02:
          ansible_host: 192.168.1.101
          ansible_user: openclaw
          ansible_ssh_private_key_file: ~/.ssh/openclaw_prod

    openclaw_ollama:
      hosts:
        ollama-server:
          ansible_host: 192.168.1.200
          ollama_models:
            - llama3.2:3b
            - mistral:7b
```

### 1.3 Variables Comunes

```yaml
# group_vars/all.yml
---
openclaw_version: "2026.3.8"
openclaw_install_dir: "/opt/openclaw"
openclaw_data_dir: "/var/lib/openclaw"
openclaw_log_dir: "/var/log/openclaw"
openclaw_user: "openclaw"
openclaw_group: "openclaw"

nodejs_version: "23.11.1"
pnpm_version: "10.23.0"
pm2_version: "5.4.3"

ollama_host: "127.0.0.1"
ollama_port: 11434

gateway_port: 18789
gateway_bind: "127.0.0.1"

# Secrets (usar ansible-vault)
# openclaw_encryption_key: !vault |
#   $ANSIBLE_VAULT;1.1;AES256
#   ...
```

### 1.4 Rol: openclaw-common

```yaml
# roles/openclaw-common/tasks/main.yml
---
- name: Crear usuario openclaw
  ansible.builtin.user:
    name: "{{ openclaw_user }}"
    group: "{{ openclaw_group }}"
    shell: /bin/bash
    home: "/home/{{ openclaw_user }}"
    create_home: true

- name: Crear directorios
  ansible.builtin.file:
    path: "{{ item }}"
    state: directory
    owner: "{{ openclaw_user }}"
    group: "{{ openclaw_group }}"
    mode: '0750'
  loop:
    - "{{ openclaw_install_dir }}"
    - "{{ openclaw_data_dir }}"
    - "{{ openclaw_log_dir }}"
    - "{{ openclaw_data_dir }}/config"
    - "{{ openclaw_data_dir }}/data"
    - "{{ openclaw_data_dir }}/logs"

- name: Instalar dependencias del sistema
  ansible.builtin.apt:
    name:
      - curl
      - wget
      - git
      - build-essential
      - python3
      - jq
    state: present
    update_cache: true
  become: true

- name: Configurar firewall UFW
  community.general.ufw:
    rule: allow
    port: "{{ item }}"
    proto: tcp
  loop:
    - "22"   # SSH
  become: true
```

### 1.5 Rol: openclaw-nodejs

```yaml
# roles/openclaw-nodejs/tasks/main.yml
---
- name: Instalar nvm
  ansible.builtin.shell: |
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  args:
    creates: "/home/{{ openclaw_user }}/.nvm"
  become_user: "{{ openclaw_user }}"

- name: Instalar Node.js
  ansible.builtin.shell: |
    source ~/.nvm/nvm.sh
    nvm install v{{ nodejs_version }}
    nvm alias default v{{ nodejs_version }}
  args:
    executable: /bin/bash
    creates: "/home/{{ openclaw_user }}/.nvm/versions/node/v{{ nodejs_version }}"
  become_user: "{{ openclaw_user }}"

- name: Instalar pnpm
  ansible.builtin.shell: |
    source ~/.nvm/nvm.sh
    npm install -g pnpm@{{ pnpm_version }}
  args:
    executable: /bin/bash
  become_user: "{{ openclaw_user }}"

- name: Instalar PM2
  ansible.builtin.shell: |
    source ~/.nvm/nvm.sh
    npm install -g pm2@{{ pm2_version }}
  args:
    executable: /bin/bash
  become_user: "{{ openclaw_user }}"

- name: Configurar PM2 startup
  ansible.builtin.shell: |
    source ~/.nvm/nvm.sh
    pm2 startup systemd -u {{ openclaw_user }} --hp /home/{{ openclaw_user }}
  args:
    executable: /bin/bash
  become_user: "{{ openclaw_user }}"
  register: pm2_startup
  changed_when: false

- name: Ejecutar comando PM2 startup
  ansible.builtin.command: "{{ pm2_startup.stdout_lines[1] }}"
  when: pm2_startup.stdout_lines | length > 1
  become: true
```

### 1.6 Rol: openclaw-gateway

```yaml
# roles/openclaw-gateway/tasks/main.yml
---
- name: Crear directorio del gateway
  ansible.builtin.file:
    path: "{{ openclaw_install_dir }}/gateway"
    state: directory
    owner: "{{ openclaw_user }}"
    group: "{{ openclaw_group }}"
    mode: '0750'

- name: Copiar código del gateway
  ansible.builtin.copy:
    src: "{{ openclaw_source_dir }}/dist/gateway/"
    dest: "{{ openclaw_install_dir }}/gateway/"
    owner: "{{ openclaw_user }}"
    group: "{{ openclaw_group }}"
    mode: '0640'

- name: Crear configuración del gateway
  ansible.builtin.template:
    src: gateway.config.json.j2
    dest: "{{ openclaw_install_dir }}/gateway/config.json"
    owner: "{{ openclaw_user }}"
    group: "{{ openclaw_group }}"
    mode: '0640'

- name: Desplegar gateway con PM2
  ansible.builtin.template:
    src: ecosystem.gateway.js.j2
    dest: "{{ openclaw_install_dir }}/gateway/ecosystem.config.js"
    owner: "{{ openclaw_user }}"
    group: "{{ openclaw_group }}"
    mode: '0640'

- name: Iniciar gateway
  ansible.builtin.shell: |
    source ~/.nvm/nvm.sh
    cd {{ openclaw_install_dir }}/gateway
    pm2 start ecosystem.config.js --only openclaw-gateway
    pm2 save
  args:
    executable: /bin/bash
  become_user: "{{ openclaw_user }}"
  changed_when: false
```

### 1.7 Rol: openclaw-agents (Concilio Tri-Agente)

```yaml
# roles/openclaw-agents/tasks/main.yml
---
- name: Crear directorio de agentes
  ansible.builtin.file:
    path: "{{ openclaw_install_dir }}/agents"
    state: directory
    owner: "{{ openclaw_user }}"
    group: "{{ openclaw_group }}"
    mode: '0750'

- name: Copiar código de agentes
  ansible.builtin.copy:
    src: "{{ openclaw_source_dir }}/dist/agents/"
    dest: "{{ openclaw_install_dir }}/agents/"
    owner: "{{ openclaw_user }}"
    group: "{{ openclaw_group }}"
    mode: '0640'

- name: Crear directorio de memoria (LanceDB)
  ansible.builtin.file:
    path: "{{ openclaw_data_dir }}/lancedb"
    state: directory
    owner: "{{ openclaw_user }}"
    group: "{{ openclaw_group }}"
    mode: '0750'

- name: Crear ecosystem.config.js para el Concilio
  ansible.builtin.template:
    src: ecosystem.agents.js.j2
    dest: "{{ openclaw_install_dir }}/agents/ecosystem.config.js"
    owner: "{{ openclaw_user }}"
    group: "{{ openclaw_group }}"
    mode: '0640'

- name: Iniciar Director
  ansible.builtin.shell: |
    source ~/.nvm/nvm.sh
    cd {{ openclaw_install_dir }}/agents
    pm2 start ecosystem.config.js --only openclaw-director
    pm2 save
  args:
    executable: /bin/bash
  become_user: "{{ openclaw_user }}"
  changed_when: false

- name: Iniciar Ejecutor
  ansible.builtin.shell: |
    source ~/.nvm/nvm.sh
    cd {{ openclaw_install_dir }}/agents
    pm2 start ecosystem.config.js --only openclaw-ejecutor
    pm2 save
  args:
    executable: /bin/bash
  become_user: "{{ openclaw_user }}"
  changed_when: false

- name: Iniciar Archivador
  ansible.builtin.shell: |
    source ~/.nvm/nvm.sh
    cd {{ openclaw_install_dir }}/agents
    pm2 start ecosystem.config.js --only openclaw-archivador
    pm2 save
  args:
    executable: /bin/bash
  become_user: "{{ openclaw_user }}"
  changed_when: false

- name: Esperar a que los agentes estén listos
  ansible.builtin.wait_for:
    port: "{{ item }}"
    host: "127.0.0.1"
    delay: 5
    timeout: 60
  loop:
    - 8081  # Director
    - 8082  # Ejecutor
    - 8083  # Archivador
```

### 1.8 Rol: openclaw-ollama

```yaml
# roles/openclaw-ollama/tasks/main.yml
---
- name: Instalar Ollama
  ansible.builtin.shell: |
    curl -fsSL https://ollama.com/install.sh | sh
  args:
    creates: /usr/local/bin/ollama
  become: true

- name: Crear servicio systemd para Ollama
  ansible.builtin.template:
    src: ollama.service.j2
    dest: /etc/systemd/system/ollama.service
    mode: '0644'
  become: true
  notify: Reiniciar Ollama

- name: Habilitar y iniciar Ollama
  ansible.builtin.systemd:
    name: ollama
    enabled: true
    state: started
    daemon_reload: true
  become: true

- name: Descargar modelos
  ansible.builtin.shell: |
    ollama pull {{ item }}
  args:
    executable: /bin/bash
  loop: "{{ ollama_models }}"
  become_user: "{{ openclaw_user }}"
  changed_when: false

- name: Verificar modelos instalados
  ansible.builtin.command: ollama list
  register: ollama_list
  changed_when: false
  become_user: "{{ openclaw_user }}"

- name: Mostrar modelos instalados
  ansible.builtin.debug:
    var: ollama_list.stdout_lines
```

### 1.9 Template: ecosystem.agents.js.j2

```javascript
{# templates/ecosystem.agents.js.j2 #}
// Concilio Tri-Agente - OPENCLAW-system
// Generado por Ansible - {{ ansible_date_time.iso8601 }}

module.exports = {
  apps: [
    // Director - Coordinador
    {
      name: 'openclaw-director',
      script: 'director.js',
      cwd: '{{ openclaw_install_dir }}/agents',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        AGENT_ROLE: 'director',
        PORT: 8081,
        REDIS_URL: 'redis://127.0.0.1:6379',
        GATEWAY_URL: 'ws://127.0.0.1:18789',
        LOG_LEVEL: '{{ openclaw_log_level | default("info") }}'
      },
      error_file: '{{ openclaw_log_dir }}/director-error.log',
      out_file: '{{ openclaw_log_dir }}/director-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      max_memory_restart: '512M',
      watch: false,
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s'
    },
    // Ejecutor - Productor
    {
      name: 'openclaw-ejecutor',
      script: 'ejecutor.js',
      cwd: '{{ openclaw_install_dir }}/agents',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        AGENT_ROLE: 'ejecutor',
        PORT: 8082,
        REDIS_URL: 'redis://127.0.0.1:6379',
        GATEWAY_URL: 'ws://127.0.0.1:18789',
        LOG_LEVEL: '{{ openclaw_log_level | default("info") }}'
      },
      error_file: '{{ openclaw_log_dir }}/ejecutor-error.log',
      out_file: '{{ openclaw_log_dir }}/ejecutor-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      max_memory_restart: '1G',
      watch: false,
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s'
    },
    // Archivador - Validador y Memoria
    {
      name: 'openclaw-archivador',
      script: 'archivador.js',
      cwd: '{{ openclaw_install_dir }}/agents',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        AGENT_ROLE: 'archivador',
        PORT: 8083,
        REDIS_URL: 'redis://127.0.0.1:6379',
        GATEWAY_URL: 'ws://127.0.0.1:18789',
        LANCEDB_PATH: '{{ openclaw_data_dir }}/lancedb',
        LOG_LEVEL: '{{ openclaw_log_level | default("info") }}'
      },
      error_file: '{{ openclaw_log_dir }}/archivador-error.log',
      out_file: '{{ openclaw_log_dir }}/archivador-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      max_memory_restart: '512M',
      watch: false,
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s'
    }
  ]
};
```

### 1.10 Playbook Principal

```yaml
# playbooks/site.yml
---
- name: Desplegar OPENCLAW-system (Concilio Tri-Agente)
  hosts: openclaw_servers
  become: true
  vars_files:
    - ../group_vars/all.yml
    - ../group_vars/secrets.yml

  pre_tasks:
    - name: Verificar API keys obligatorias
      ansible.builtin.fail:
        msg: |
          ERROR: Debe configurar al menos una API key en secrets.yml:
          - ZHIPUAI_API_KEY (recomendado)
          - OPENAI_API_KEY
          - ANTHROPIC_API_KEY
      when: >
        (zhipuai_api_key is not defined or zhipuai_api_key == '') and
        (openai_api_key is not defined or openai_api_key == '') and
        (anthropic_api_key is not defined or anthropic_api_key == '')
      run_once: true

  roles:
    - role: openclaw-common
      tags: [common, setup]

    - role: openclaw-nodejs
      tags: [nodejs, setup]

    - role: openclaw-redis
      tags: [redis, infrastructure]

    - role: openclaw-ollama
      tags: [ollama]
      when: ollama_local | default(false)

    - role: openclaw-agents
      tags: [agents, concilio]

    - role: openclaw-gateway
      tags: [gateway]

  post_tasks:
    - name: Esperar a que todos los servicios estén listos
      ansible.builtin.wait_for:
        port: "{{ item }}"
        host: "127.0.0.1"
        delay: 5
        timeout: 120
      loop:
        - 6379   # Redis
        - 8081   # Director
        - 8082   # Ejecutor
        - 8083   # Archivador
        - 18789  # Gateway

    - name: Verificar estado de PM2
      ansible.builtin.command: pm2 status
      register: pm2_status
      changed_when: false
      become_user: "{{ openclaw_user }}"

    - name: Mostrar estado del Concilio
      ansible.builtin.debug:
        var: pm2_status.stdout_lines

    - name: Verificar health del Gateway
      ansible.builtin.uri:
        url: "http://127.0.0.1:18789/health"
        method: GET
        status_code: 200
      register: gateway_health
      retries: 3
      delay: 5

    - name: Despliegue exitoso
      ansible.builtin.debug:
        msg: |
          ✅ OPENCLAW-system desplegado correctamente
          Concilio Tri-Agente: Director (8081) → Ejecutor (8082) → Archivador (8083)
          Gateway: http://127.0.0.1:18789
```

### 1.11 Template de Environment

```jinja2
{# templates/env.j2 #}
# Generado por Ansible - {{ ansible_date_time.iso8601 }}
# Concilio Tri-Agente - OPENCLAW-system

NODE_ENV=production
LOG_LEVEL=info

# === CONCILIO TRI-AGENTE ===
DIRECTOR_PORT=8081
EJECUTOR_PORT=8082
ARCHIVADOR_PORT=8083

# === GATEWAY ===
GATEWAY_URL=ws://{{ gateway_bind }}:{{ gateway_port }}
GATEWAY_TOKEN={{ openclaw_gateway_token }}
GATEWAY_BIND={{ gateway_bind }}
GATEWAY_PORT={{ gateway_port }}

# === REDIS (Message Broker) ===
REDIS_URL=redis://127.0.0.1:6379

# === SEGURIDAD ===
OPENCLAW_ENCRYPTION_KEY={{ openclaw_encryption_key }}

# === MEMORIA (LanceDB) ===
LANCEDB_PATH={{ openclaw_data_dir }}/lancedb
MEMORY_ENABLED=true

# === OLLAMA (Local LLM) ===
OLLAMA_HOST={{ ollama_host }}:{{ ollama_port }}
OLLAMA_DEFAULT_MODEL={{ ollama_default_model | default('llama3.2:3b') }}

# === LLM PROVIDERS (al menos uno obligatorio) ===
ZHIPUAI_API_KEY={{ zhipuai_api_key | default('') }}
# OPENAI_API_KEY={{ openai_api_key | default('') }}
# ANTHROPIC_API_KEY={{ anthropic_api_key | default('') }}
# MINIMAX_API_KEY={{ minimax_api_key | default('') }}

# === CANALES ===
TELEGRAM_BOT_TOKEN={{ telegram_bot_token | default('') }}
TELEGRAM_ALLOWED_USERS={{ telegram_allowed_users | default('') }}
```

### 1.12 Ejecución de Playbooks

```bash
# Verificar conectividad
ansible -i inventory/production.yml all -m ping

# Dry run
ansible-playbook -i inventory/production.yml playbooks/site.yml --check

# Ejecutar completo
ansible-playbook -i inventory/production.yml playbooks/site.yml

# Solo actualizar código
ansible-playbook -i inventory/production.yml playbooks/upgrade.yml --tags code

# Usar vault para secrets
ansible-playbook -i inventory/production.yml playbooks/site.yml --ask-vault-pass
```

---

## 2. Terraform

### 2.1 Estructura de Directorios

```
terraform/
├── modules/
│   ├── openclaw-server/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── openclaw-database/
├── environments/
│   ├── production/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── staging/
├── providers.tf
└── versions.tf
```

### 2.2 Módulo: openclaw-server

```hcl
# modules/openclaw-server/main.tf

variable "name" {
  description = "Nombre del servidor"
  type        = string
}

variable "size" {
  description = "Tamaño del servidor"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "region" {
  description = "Región del servidor"
  type        = string
  default     = "nyc1"
}

variable "ssh_keys" {
  description = "IDs de claves SSH"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags del servidor"
  type        = list(string)
  default     = ["openclaw"]
}

resource "digitalocean_droplet" "openclaw" {
  image  = "ubuntu-24-04-x64"
  name   = var.name
  region = var.region
  size   = var.size
  ssh_keys = var.ssh_keys
  tags   = var.tags

  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "apt update",
      "apt install -y python3 python3-pip",
      "pip3 install ansible",
    ]
  }
}

output "ipv4_address" {
  value = digitalocean_droplet.openclaw.ipv4_address
}

output "name" {
  value = digitalocean_droplet.openclaw.name
}
```

### 2.3 Configuración de Producción

```hcl
# environments/production/main.tf

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    endpoint                    = "nyc3.digitaloceanspaces.com"
    region                      = "us-east-1"
    key                         = "openclaw-production/terraform.tfstate"
    bucket                      = "openclaw-terraform-state"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

provider "digitalocean" {
  token = var.do_token
}

module "openclaw_production" {
  source     = "../../modules/openclaw-server"
  name       = "openclaw-prod-01"
  size       = "s-4vcpu-8gb"  # 8GB RAM para Llama 3.2
  region     = "nyc1"
  ssh_keys   = var.ssh_key_ids
  tags       = ["openclaw", "production"]
}

resource "digitalocean_firewall" "openclaw" {
  name = "openclaw-firewall"

  droplet_ids = [module.openclaw_production.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.ssh_allowed_ips
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "2222"
    source_addresses = var.ssh_allowed_ips
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
```

### 2.4 Variables

```hcl
# environments/production/variables.tf

variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "ssh_key_ids" {
  description = "IDs de claves SSH en DigitalOcean"
  type        = list(string)
}

variable "ssh_allowed_ips" {
  description = "IPs permitidas para SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restringir en producción
}
```

```hcl
# environments/production/terraform.tfvars

ssh_key_ids   = ["12345678"]
ssh_allowed_ips = [
  "192.168.1.0/24",
  "10.0.0.1/32"
]
```

### 2.5 Outputs

```hcl
# environments/production/outputs.tf

output "server_ip" {
  value       = module.openclaw_production.ipv4_address
  description = "IP pública del servidor OPENCLAW"
}

output "ansible_inventory" {
  value = <<EOF
[openclaw_servers]
${module.openclaw_production.name} ansible_host=${module.openclaw_production.ipv4_address} ansible_user=root
EOF
  description = "Entrada de inventory para Ansible"
}
```

### 2.6 Comandos Terraform

```bash
# Inicializar
terraform init

# Verificar plan
terraform plan -var-file="terraform.tfvars"

# Aplicar
terraform apply -var-file="terraform.tfvars"

# Ver outputs
terraform output

# Destruir (cuidado!)
terraform destroy -var-file="terraform.tfvars"
```

---

## 3. Integración Ansible + Terraform

### 3.1 Flujo de Trabajo

```bash
#!/bin/bash
# deploy.sh - Script de despliegue completo

set -e

echo "1. Provisionando infraestructura..."
cd terraform/environments/production
terraform apply -auto-approve

echo "2. Generando inventory de Ansible..."
terraform output -raw ansible_inventory > ../../ansible/inventory/terraform.yml

echo "3. Ejecutando Ansible..."
cd ../../ansible
ansible-playbook -i inventory/terraform.yml playbooks/site.yml

echo "4. Verificando despliegue..."
ansible -i inventory/terraform.yml all -m shell -a "pm2 status"

echo "✅ Despliegue completado"
```

---

## 4. Checklist de Automatización

```markdown
## Pre-Requisitos
- [ ] Terraform >= 1.5.0 instalado
- [ ] Ansible >= 2.15 instalado
- [ ] Credenciales de cloud provider
- [ ] Claves SSH configuradas

## Terraform
- [ ] Backend configurado (S3/DO Spaces)
- [ ] Variables sensibles en vault
- [ ] Firewall configurado
- [ ] Outputs generados

## Ansible
- [ ] Inventory generado
- [ ] Roles probados localmente
- [ ] Vault para secrets
- [ ] Idempotencia verificada

## Integración
- [ ] Script deploy.sh probado
- [ ] Rollback documentado
- [ ] Monitoreo configurado
```

---

**Documento:** Automatización Ansible/Terraform
**ID:** DOC-IMP-IAC-001
**Versión:** 1.0
**Fecha:** 2026-03-10
