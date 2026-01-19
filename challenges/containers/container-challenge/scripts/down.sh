#!/bin/bash
#
# Script para parar e limpar o ambiente Open5GS containerizado
# Atende aos requisitos do desafio de containers:
# - Para todos os serviços
# - Remove containers
# - Remove redes (opcional)
# - Remove volumes (opcional, com confirmação)
#
# Uso:
#   ./scripts/down.sh           - Para serviços mantendo volumes
#   ./scripts/down.sh --volumes - Para serviços e remove volumes (⚠️ apaga dados)
#
# Autor: Jonas Augusto Kunzler
# Data: 2026-01-16

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

# Verificar argumentos
REMOVE_VOLUMES=false
if [ "$1" = "--volumes" ] || [ "$1" = "-v" ]; then
    REMOVE_VOLUMES=true
fi

echo "=========================================="
echo "Open5GS Containerizado - Parando Ambiente"
echo "=========================================="
echo ""

# ============================================================================
# 1. Verificar se há serviços rodando
# ============================================================================

echo -e "${BLUE}1. Verificando serviços ativos...${NC}"

if ! docker compose ps | grep -q "Up"; then
    echo -e "  ${YELLOW}⚠️  Nenhum serviço está rodando${NC}"
    echo ""
else
    echo -e "  ${GREEN}✅ Serviços encontrados${NC}"
    echo ""
    echo "  Serviços ativos:"
    docker compose ps --format "table {{.Name}}\t{{.Status}}" | grep -v "NAME" || true
    echo ""
fi

# ============================================================================
# 2. Aviso sobre remoção de volumes
# ============================================================================

if [ "$REMOVE_VOLUMES" = true ]; then
    echo -e "${RED}⚠️  ATENÇÃO: Você está prestes a remover volumes!${NC}"
    echo ""
    echo "  Isso irá apagar TODOS os dados persistidos, incluindo:"
    echo "    - Dados do MongoDB (subscribers, configurações)"
    echo "    - Configurações do MongoDB"
    echo ""
    echo -e "  ${YELLOW}Volumes que serão removidos:${NC}"
    docker compose config --volumes 2>/dev/null | while read volume; do
        echo "    - $volume"
    done
    echo ""
    
    read -p "  Deseja continuar? (digite 'sim' para confirmar): " CONFIRM
    if [ "$CONFIRM" != "sim" ]; then
        echo ""
        echo -e "${YELLOW}Operação cancelada. Volumes serão mantidos.${NC}"
        REMOVE_VOLUMES=false
    fi
    echo ""
fi

# ============================================================================
# 3. Parar Serviços
# ============================================================================

echo -e "${BLUE}2. Parando serviços...${NC}"

if docker compose down; then
    echo -e "  ${GREEN}✅ Serviços parados${NC}"
else
    echo -e "  ${YELLOW}⚠️  Alguns serviços podem não ter sido parados corretamente${NC}"
fi

echo ""

# ============================================================================
# 4. Remover Volumes (se solicitado)
# ============================================================================

if [ "$REMOVE_VOLUMES" = true ]; then
    echo -e "${BLUE}3. Removendo volumes...${NC}"
    
    # Listar volumes antes de remover
    VOLUMES=$(docker compose config --volumes 2>/dev/null || echo "")
    
    if [ -n "$VOLUMES" ]; then
        for volume in $VOLUMES; do
            VOLUME_NAME="${PROJECT_DIR##*/}_${volume}"
            if docker volume inspect "$VOLUME_NAME" > /dev/null 2>&1; then
                echo "  Removendo volume: $volume"
                docker volume rm "$VOLUME_NAME" > /dev/null 2>&1 || true
            fi
        done
        echo -e "  ${GREEN}✅ Volumes removidos${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Nenhum volume encontrado${NC}"
    fi
    echo ""
else
    echo -e "${BLUE}3. Volumes mantidos (dados preservados)${NC}"
    echo ""
    echo "  Volumes preservados:"
    docker compose config --volumes 2>/dev/null | while read volume; do
        VOLUME_NAME="${PROJECT_DIR##*/}_${volume}"
        if docker volume inspect "$VOLUME_NAME" > /dev/null 2>&1; then
            VOLUME_SIZE=$(docker volume inspect "$VOLUME_NAME" --format '{{ .Mountpoint }}' | xargs du -sh 2>/dev/null | cut -f1 || echo "N/A")
            echo "    - $volume ($VOLUME_SIZE)"
        fi
    done
    echo ""
fi

# ============================================================================
# 5. Verificar Redes
# ============================================================================

echo -e "${BLUE}4. Verificando redes...${NC}"

NETWORKS=$(docker compose config --networks 2>/dev/null | grep -v "^networks:" | grep -v "^  " | sed 's/://' | xargs || echo "")

if [ -n "$NETWORKS" ]; then
    echo "  Redes Docker Compose:"
    for network in $NETWORKS; do
        NETWORK_NAME="${PROJECT_DIR##*/}_${network}"
        if docker network inspect "$NETWORK_NAME" > /dev/null 2>&1; then
            echo "    - $network (ativa)"
        else
            echo "    - $network (removida)"
        fi
    done
else
    echo -e "  ${YELLOW}⚠️  Nenhuma rede customizada encontrada${NC}"
fi

echo ""

# ============================================================================
# 6. Resumo Final
# ============================================================================

echo "=========================================="
echo -e "${GREEN}✅ Ambiente parado com sucesso!${NC}"
echo "=========================================="
echo ""

if [ "$REMOVE_VOLUMES" = true ]; then
    echo -e "${YELLOW}⚠️  Volumes foram removidos (dados apagados)${NC}"
    echo ""
    echo "  Para reiniciar do zero:"
    echo "    ./scripts/up.sh"
else
    echo "📦 Dados Preservados:"
    echo "  - Volumes mantidos (dados do MongoDB preservados)"
    echo "  - Logs mantidos em ./logs/"
    echo "  - Configurações mantidas em ./configs/"
    echo ""
    echo "  Para reiniciar com dados existentes:"
    echo "    ./scripts/up.sh"
fi

echo ""
echo "💡 Comandos Úteis:"
echo "  - Reiniciar: ./scripts/up.sh"
echo "  - Limpar tudo: ./scripts/down.sh --volumes"
echo "  - Ver volumes: docker volume ls"
echo "  - Ver redes: docker network ls"
echo ""
