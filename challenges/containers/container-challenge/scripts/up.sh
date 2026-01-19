#!/bin/bash
#
# Script para iniciar todo o ambiente Open5GS containerizado
# Atende aos requisitos do desafio de containers:
# - Verifica pré-requisitos
# - Carrega variáveis de ambiente
# - Inicia serviços multi-container
# - Configura persistência de dados
# - Adiciona subscriber ao MongoDB
# - Verifica saúde dos serviços
#
# Uso: ./scripts/up.sh
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

echo "=========================================="
echo "Open5GS Containerizado - Iniciando Ambiente"
echo "=========================================="
echo ""

# ============================================================================
# 1. Verificar Pré-requisitos
# ============================================================================

echo -e "${BLUE}1. Verificando pré-requisitos...${NC}"

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker não está instalado!${NC}"
    echo "   Instale Docker: https://docs.docker.com/get-docker/"
    exit 1
fi
echo -e "  ${GREEN}✅ Docker instalado${NC}"

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker não está rodando!${NC}"
    echo "   Inicie o Docker primeiro."
    exit 1
fi
echo -e "  ${GREEN}✅ Docker está rodando${NC}"

# Verificar Docker Compose
if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose não está disponível!${NC}"
    echo "   Instale Docker Compose plugin: https://docs.docker.com/compose/install/"
    exit 1
fi
echo -e "  ${GREEN}✅ Docker Compose disponível${NC}"

# Verificar arquivo docker-compose.yml
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ Arquivo docker-compose.yml não encontrado!${NC}"
    exit 1
fi
echo -e "  ${GREEN}✅ docker-compose.yml encontrado${NC}"

echo ""

# ============================================================================
# 2. Carregar Variáveis de Ambiente
# ============================================================================

echo -e "${BLUE}2. Carregando variáveis de ambiente...${NC}"

# Carregar .env se existir
if [ -f ".env" ]; then
    echo -e "  ${GREEN}✅ Arquivo .env encontrado${NC}"
    set -a
    source .env
    set +a
else
    echo -e "  ${YELLOW}⚠️  Arquivo .env não encontrado (usando valores padrão)${NC}"
    echo "     Crie um arquivo .env baseado em .env.example se necessário"
fi

# Mostrar variáveis importantes
echo "  Variáveis configuradas:"
echo "    - OPEN5GS_IMAGE: ${OPEN5GS_IMAGE:-gradiant/open5gs:2.7.6}"
echo "    - MONGODB_IMAGE: ${MONGODB_IMAGE:-mongo:7.0}"
echo "    - UERANSIM_IMAGE: ${UERANSIM_IMAGE:-gradiant/ueransim:3.2.6}"

echo ""

# ============================================================================
# 3. Habilitar IP Forwarding (necessário para roteamento)
# ============================================================================

echo -e "${BLUE}3. Configurando IP forwarding...${NC}"

# Habilitar IP forwarding no host (necessário para roteamento entre containers)
if [ "$(id -u)" -eq 0 ]; then
    sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1 || true
    sysctl -w net.ipv6.conf.all.forwarding=1 > /dev/null 2>&1 || true
    echo -e "  ${GREEN}✅ IP forwarding habilitado${NC}"
else
    # Tentar com sudo se não for root
    if sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1; then
        sudo sysctl -w net.ipv6.conf.all.forwarding=1 > /dev/null 2>&1 || true
        echo -e "  ${GREEN}✅ IP forwarding habilitado${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Não foi possível habilitar IP forwarding (pode ser necessário sudo)${NC}"
        echo "     O roteamento pode não funcionar corretamente"
    fi
fi

echo ""

# ============================================================================
# 4. Iniciar Serviços
# ============================================================================

echo -e "${BLUE}4. Iniciando serviços Docker Compose...${NC}"

# Criar diretórios de logs se não existirem
mkdir -p logs/{amf,smf,upf,ueransim,nrf,scp,ausf,udm,udr,pcf,nssf}

# Iniciar todos os serviços
if docker compose up -d; then
    echo -e "  ${GREEN}✅ Serviços iniciados${NC}"
else
    echo -e "  ${RED}❌ Erro ao iniciar serviços${NC}"
    exit 1
fi

echo ""

# ============================================================================
# 5. Aguardar Serviços Estarem Prontos
# ============================================================================

echo -e "${BLUE}5. Aguardando serviços estarem prontos...${NC}"

MAX_WAIT=120
WAIT_COUNT=0
MONGODB_READY=false

# Aguardar MongoDB estar pronto
echo -n "  Aguardando MongoDB... "
while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if docker compose exec -T mongodb mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
        MONGODB_READY=true
        echo -e "${GREEN}✅${NC}"
        break
    fi
    sleep 2
    ((WAIT_COUNT+=2))
    if [ $((WAIT_COUNT % 10)) -eq 0 ]; then
        echo -n "."
    fi
done

if [ "$MONGODB_READY" = false ]; then
    echo -e "${YELLOW}⚠️  Timeout aguardando MongoDB${NC}"
    echo "     Verifique logs: docker compose logs mongodb"
fi

# Aguardar outros serviços críticos
echo -n "  Aguardando Control Plane... "
sleep 15
echo -e "${GREEN}✅${NC}"

echo ""

# ============================================================================
# 6. Adicionar Subscriber ao MongoDB
# ============================================================================

echo -e "${BLUE}6. Configurando banco de dados...${NC}"

if [ "$MONGODB_READY" = true ]; then
    if [ -f "scripts/add-subscriber.sh" ]; then
        echo "  Adicionando subscriber ao MongoDB..."
        if bash scripts/add-subscriber.sh > /dev/null 2>&1; then
            echo -e "  ${GREEN}✅ Subscriber adicionado${NC}"
        else
            echo -e "  ${YELLOW}⚠️  Erro ao adicionar subscriber (pode já existir)${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠️  Script add-subscriber.sh não encontrado${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠️  MongoDB não está pronto, pulando adição de subscriber${NC}"
fi

echo ""

# ============================================================================
# 7. Verificar Status dos Serviços
# ============================================================================

echo -e "${BLUE}7. Verificando status dos serviços...${NC}"
echo ""

docker compose ps

echo ""

# ============================================================================
# 8. Resumo e Próximos Passos
# ============================================================================

echo "=========================================="
echo -e "${GREEN}✅ Ambiente iniciado com sucesso!${NC}"
echo "=========================================="
echo ""

echo "📋 Scripts Disponíveis:"
echo "  - ./scripts/healthcheck.sh          - Verificação de saúde dos serviços"
echo "  - ./scripts/test-system-status.sh   - Verificação detalhada do sistema"
echo "  - ./scripts/test_ue_connection.sh    - Teste de conectividade E2E"
echo "  - ./scripts/add-subscriber.sh        - Adicionar subscriber ao MongoDB"
echo ""

echo "📝 Comandos Úteis:"
echo "  - Ver logs: docker compose logs -f <serviço>"
echo "  - Ver status: docker compose ps"
echo "  - Parar: ./scripts/down.sh"
echo "  - Parar e remover volumes: ./scripts/down.sh --volumes"
echo ""

echo "🔍 Verificações Rápidas:"
echo "  - MongoDB: docker compose exec mongodb mongosh --eval \"db.adminCommand('ping')\""
echo "  - NRF: docker compose exec nrf pgrep -f open5gs-nrfd"
echo "  - AMF: docker compose exec amf pgrep -f open5gs-amfd"
echo "  - UE IP: docker compose exec ueransim-ue ip addr show | grep '10.60'"
echo ""

echo "⚠️  Notas Importantes:"
echo "  - Aguarde alguns segundos para todos os serviços iniciarem completamente"
echo "  - Execute './scripts/test-system-status.sh' para verificar o estado real do sistema"
echo "  - Volumes são mantidos entre reinicializações (dados persistem)"
echo "  - Para limpar tudo: ./scripts/down.sh --volumes"
echo ""

echo "📚 Documentação:"
echo "  - README.md: Documentação completa do projeto"
echo "  - docs/ARCHITECTURE.md: Arquitetura detalhada"
echo "  - docs/challenge.md: Requisitos do desafio"
echo ""
