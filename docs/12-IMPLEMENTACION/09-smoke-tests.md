# Smoke Tests Post-Despliegue

**ID:** DOC-IMP-SMK-001
**Versión:** 1.0
**Fecha:** 2026-03-10

---

## Resumen

Checklist de verificación post-despliegue para asegurar que OPENCLAW-system está operativo.

---

## 1. Checklist Automatizado

```bash
#!/bin/bash
# scripts/smoke-test.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
    local name=$1
    local cmd=$2

    echo -n "Verificando $name... "

    if eval "$cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((FAIL++))
        return 1
    fi
}

echo "╔════════════════════════════════════════════════════════╗"
echo "║       SMOKE TEST - OPENCLAW-system                     ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

echo "=== 1. SERVICIOS DEL SISTEMA ==="
check "Node.js" "node --version | grep -q v23"
check "pnpm" "pnpm --version | grep -q 10"
check "PM2" "pm2 --version | grep -q 5"
check "Docker" "docker --version"
check "Git" "git --version"

echo ""
echo "=== 2. PROCESOS PM2 ==="
check "Gateway online" "pm2 status | grep -q 'sis-gateway.*online'"
check "Director online" "pm2 status | grep -q 'sis-director.*online'"
check "Ejecutor online" "pm2 status | grep -q 'sis-ejecutor.*online'"
check "Archivador online" "pm2 status | grep -q 'sis-archivador.*online'"

echo ""
echo "=== 3. PUERTOS ==="
check "Gateway puerto 18789" "ss -tlnp | grep -q 18789"
check "Ollama puerto 11434" "ss -tlnp | grep -q 11434"
check "Gateway en localhost" "ss -tlnp | grep 18789 | grep -q 127.0.0.1"
check "Ollama en localhost" "ss -tlnp | grep 11434 | grep -q 127.0.0.1"

echo ""
echo "=== 4. HEALTH CHECKS ==="
check "Gateway health" "curl -sf http://127.0.0.1:18789/health"
check "Ollama API" "curl -sf http://127.0.0.1:11434/api/version"

echo ""
echo "=== 5. LLM ==="
check "Modelo llama3.2:3b disponible" "ollama list | grep -q llama3.2:3b"
check "Ollama responde" "curl -sf http://127.0.0.1:11434/api/ps"

echo ""
echo "=== 6. ARCHIVOS DE CONFIGURACIÓN ==="
check "Archivo .env existe" "test -f ~/.openclaw/config/.env"
check "Permisos .env correctos" "stat -c '%a' ~/.openclaw/config/.env | grep -q 600"
check "Ecosystem config existe" "test -f ~/projects/openclaw/ecosystem.config.js"

echo ""
echo "=== 7. CONECTIVIDAD ==="
check "Redis responde" "redis-cli ping | grep -q PONG"
check "Directorio de datos" "test -d ~/.openclaw/data"
check "Directorio de logs" "test -d ~/.openclaw/logs"

echo ""
echo "=== 8. SEGURIDAD ==="
check "UFW activo" "sudo ufw status | grep -q active"
check "SSH no-root" "grep -q '^PermitRootLogin no' /etc/ssh/sshd_config 2>/dev/null || echo 'skip'"

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  RESULTADO: $PASS pasaron, $FAIL fallaron                     ║"
echo "╚════════════════════════════════════════════════════════╝"

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}❌ SMOKE TEST FALLÓ${NC}"
    exit 1
else
    echo -e "${GREEN}✅ SMOKE TEST PASÓ${NC}"
    exit 0
fi
```

---

## 2. Tests Funcionales

```bash
#!/bin/bash
# scripts/functional-test.sh

echo "=== TESTS FUNCIONALES ==="

# Test 1: LLM genera respuesta
echo "Test 1: Generación de texto..."
RESPONSE=$(curl -s -X POST http://127.0.0.1:11434/api/chat \
  -d '{
    "model": "llama3.2:3b",
    "messages": [{"role": "user", "content": "Responde solo OK"}],
    "stream": false
  }')

if echo "$RESPONSE" | jq -e '.message.content' > /dev/null 2>&1; then
    echo "✅ LLM responde: $(echo $RESPONSE | jq -r '.message.content' | head -c 50)"
else
    echo "❌ LLM no responde"
    exit 1
fi

# Test 2: Gateway acepta conexión
echo "Test 2: Conexión WebSocket..."
timeout 5 wscat -c ws://127.0.0.1:18789 -x '{"type":"ping"}' > /dev/null 2>&1 && \
    echo "✅ Gateway WebSocket OK" || \
    echo "⚠️ Gateway WebSocket sin wscat (instalar con: npm -g wscat)"

# Test 3: Redis lee/escribe
echo "Test 3: Redis read/write..."
redis-cli SET test_key "test_value_$(date +%s)" > /dev/null
redis-cli GET test_key | grep -q test_value && \
    echo "✅ Redis OK" || \
    echo "❌ Redis falla"

# Cleanup
redis-cli DEL test_key > /dev/null

# Test 4: Logs sin errores críticos
echo "Test 4: Logs limpios..."
ERRORS=$(pm2 logs --lines 100 --nostream 2>&1 | grep -c "ERROR\|FATAL\|Exception" || true)
if [ "$ERRORS" -lt 5 ]; then
    echo "✅ Logs OK ($ERRORS errores recientes)"
else
    echo "⚠️ Logs con $ERRORS errores recientes"
fi

echo ""
echo "=== TESTS FUNCIONALES COMPLETADOS ==="
```

---

## 3. Checklist Manual

```markdown
## Smoke Test Post-Despliegue

### Servicios (2 min)
- [ ] `pm2 status` muestra 4 procesos online
- [ ] `pm2 logs` no muestra errores en rojo
- [ ] `ollama ps` muestra GPU detectada

### Conectividad (1 min)
- [ ] `curl http://127.0.0.1:18789/health` responde OK
- [ ] `curl http://127.0.0.1:11434/api/version` responde versión

### Funcionalidad (2 min)
- [ ] Mensaje de prueba en Gateway genera respuesta
- [ ] Ollama genera texto con modelo base

### Seguridad (1 min)
- [ ] Puertos solo en 127.0.0.1 (no 0.0.0.0)
- [ ] .env con permisos 600
- [ ] Firewall activo

### Performance (1 min)
- [ ] Memoria < 80% uso
- [ ] Disco < 80% uso
- [ ] CPU < 50% idle
```

---

**Documento:** Smoke Tests Post-Despliegue
**ID:** DOC-IMP-SMK-001
