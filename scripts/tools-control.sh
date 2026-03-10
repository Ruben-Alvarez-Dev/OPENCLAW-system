#!/bin/bash
# tools-control.sh - Control de servicios OPENCLAW-system

case "$1" in
    maestro)
        cd /Users/ruben/JartOS/TIERS/TIER-01-ACCESS/10150-maestro
        case "$2" in
            start)
                docker-compose up -d
                echo "⏳ MAESTRO iniciando (puede tardar 5-10 min la primera vez)..."
                sleep 30
                echo "✅ MAESTRO iniciado en http://localhost"
                ;;
            stop)
                docker-compose down
                echo "✅ MAESTRO detenido"
                ;;
            status)
                docker-compose ps
                ;;
            logs)
                docker-compose logs -f maestro-backend
                ;;
            *)
                echo "Uso: $0 maestro {start|stop|status|logs}"
                ;;
        esac
        ;;
    servicios)
        echo "=== Estado de Servicios OPENCLAW ==="
        echo ""
        echo "🔬 MAESTRO:"
        curl -s http://localhost/health 2>/dev/null && echo "  ✅ Operativo" || echo "  ❌ No disponible"
        echo ""
        echo "🚀 Gateway (18789):"
        curl -s http://127.0.0.1:18789/health 2>/dev/null && echo "" || echo "  ❌ No disponible"
        echo ""
        echo "📊 PM2:"
        pm2 list
        ;;
    *)
        echo "Uso: $0 {maestro|servicios}"
        echo ""
        echo "Comandos disponibles:"
        echo "  $0 maestro {start|stop|status|logs}"
        echo "  $0 servicios"
        ;;
esac
