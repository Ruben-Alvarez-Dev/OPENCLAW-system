#!/bin/bash
# tools-control.sh - Control de herramientas de investigación OPENCLAW

case "$1" in
    gpt-researcher)
        cd /Users/ruben/JartOS/TIERS/TIER-01-ACCESS/10120-gpt-researcher
        case "$2" in
            start)
                docker-compose up -d
                echo "✅ GPT Researcher iniciado en http://localhost:11020"
                ;;
            stop)
                docker-compose down
                echo "✅ GPT Researcher detenido"
                ;;
            status)
                docker-compose ps
                ;;
            logs)
                docker-compose logs -f
                ;;
            *)
                echo "Uso: $0 gpt-researcher {start|stop|status|logs}"
                ;;
        esac
        ;;
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
    engram)
        case "$2" in
            stats)
                engram stats
                ;;
            search)
                shift 3
                if [ -z "$3" ]; then
                    echo "Uso: $0 engram search <query>"
                    exit 1
                fi
                engram search "$3"
                ;;
            save)
                shift 3
                if [ -z "$3" ] || [ -z "$4" ]; then
                    echo "Uso: $0 engram save <title> <content>"
                    exit 1
                fi
                engram save "$3" "$4"
                ;;
            context)
                engram context openclaw
                ;;
            *)
                echo "Uso: $0 engram {stats|search|save|context}"
                ;;
        esac
        ;;
    status)
        echo "=== Estado de Herramientas OPENCLAW ==="
        echo ""
        echo "📚 GPT Researcher:"
        curl -s http://localhost:11020/ 2>/dev/null || echo "  ✅ Operativo" || echo "  ❌ No disponible"
        echo ""
        echo "🔬 MAESTRO:"
        curl -s http://localhost/health 2>/dev/null || echo "  ✅ Operativo" || echo "  ❌ No disponible"
        echo ""
        echo "💾 Engram:"
        engram stats
        ;;
    *)
        echo "Uso: $0 {gpt-researcher|maestro|engram|status}"
        echo ""
        echo "Comandos disponibles:"
        echo "  $0 gpt-researcher {start|stop|status|logs}"
        echo "  $0 maestro {start|stop|status|logs}"
        echo "  $0 engram {stats|search|save|context}"
        echo "  $0 status"
        ;;
esac
