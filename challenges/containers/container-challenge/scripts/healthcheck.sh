#!/bin/bash
# Script para verificar a saúde dos serviços Open5GS
# Detecta problemas conhecidos e fornece informações relevantes
# Uso: ./scripts/healthcheck.sh
#
# Autor: Jonas Augusto Kunzler
# Data: 2026-01-15

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Healthcheck - Laboratório Open5GS"
echo "=========================================="
echo ""

# Verificar status dos containers
echo "Status dos containers:"
docker compose ps
echo ""

# Verificar processos dos serviços
echo "Verificando processos dos serviços..."
declare -A SERVICE_CONTAINERS=(
    ["nrf"]="open5gs-nrf-rocket"
    ["scp"]="open5gs-scp-rocket"
    ["amf"]="open5gs-amf-rocket"
    ["smf"]="open5gs-smf-rocket"
    ["ausf"]="open5gs-ausf-rocket"
    ["udm"]="open5gs-udm-rocket"
    ["udr"]="open5gs-udr-rocket"
    ["pcf"]="open5gs-pcf-rocket"
    ["nssf"]="open5gs-nssf-rocket"
    ["upf"]="open5gs-upf-rocket"
)

for service in "${!SERVICE_CONTAINERS[@]}"; do
    container="${SERVICE_CONTAINERS[$service]}"
    if docker exec "$container" pgrep -f "open5gs-" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ ${service} está rodando${NC}"
    else
        echo -e "${RED}✗ ${service} não está rodando${NC}"
    fi
done
echo ""

# Verificar conectividade NRF
echo "Verificando NRF..."
# NRF usa HTTP/2 puro (nghttp2) que não é facilmente testável com curl simples
# Verificamos se o processo está rodando e se a porta está escutando
if docker exec open5gs-nrf-rocket pgrep -f "open5gs-nrfd" > /dev/null 2>&1; then
    if docker exec open5gs-nrf-rocket netstat -tlnp 2>/dev/null | grep -q ":7777" || \
       docker exec open5gs-nrf-rocket ss -tlnp 2>/dev/null | grep -q ":7777"; then
        echo -e "${GREEN}✓ NRF está rodando e escutando na porta 7777${NC}"
    else
        echo -e "${YELLOW}⚠ NRF está rodando mas porta 7777 não está escutando${NC}"
    fi
else
    echo -e "${RED}✗ NRF não está rodando${NC}"
fi
echo ""

# Verificar se NFs estão registradas no NRF
echo "Verificando registro de NFs no NRF..."
# Nota: O endpoint HTTP/2 do NRF requer cliente HTTP/2 nativo (nghttp2)
# Como alternativa, verificamos se as NFs estão rodando e se o NRF está healthy
# O registro real é verificado pelos logs e pelo fato de as NFs estarem funcionando
if docker compose ps nrf | grep -q "healthy"; then
    echo "✓ NRF está healthy (NFs devem estar registradas)"
    echo "  (Para verificar registro detalhado, consulte os logs: docker compose logs nrf | grep 'NF registered')"
else
    echo "⚠ NRF não está healthy ainda"
fi
echo ""

# Verificar conectividade entre serviços
echo "Verificando conectividade de rede..."
echo "Testando N2 (AMF <-> gNB):"
if docker exec open5gs-amf-rocket ping -c 1 10.20.0.100 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ AMF pode alcançar gNB${NC}"
else
    echo -e "${RED}✗ AMF não pode alcançar gNB${NC}"
fi

echo "Testando N3 (gNB <-> UPF):"
if docker exec ueransim-gnb-rocket ping -c 1 10.30.0.21 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ gNB pode alcançar UPF${NC}"
else
    echo -e "${RED}✗ gNB não pode alcançar UPF${NC}"
fi

echo "Testando N4 (SMF <-> UPF):"
if docker exec open5gs-smf-rocket ping -c 1 10.40.0.21 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ SMF pode alcançar UPF${NC}"
else
    echo -e "${RED}✗ SMF não pode alcançar UPF${NC}"
fi

echo "Testando N6 (UPF <-> DN):"
if docker exec open5gs-upf-rocket ping -c 1 10.50.0.100 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ UPF pode alcançar DN${NC}"
else
    echo -e "${RED}✗ UPF não pode alcançar DN${NC}"
fi
echo ""

# Verificar NG Setup
echo "Verificando NG Setup (gNB <-> AMF)..."
NG_SETUP_SUCCESS=$(docker compose logs ueransim-gnb-rocket 2>&1 | grep -c "NG Setup procedure is successful" 2>/dev/null | head -1 || echo "0")
if [ "$NG_SETUP_SUCCESS" -gt 0 ] 2>/dev/null; then
    echo -e "${GREEN}✓ NG Setup bem-sucedido ($NG_SETUP_SUCCESS vez(es))${NC}"
else
    echo -e "${YELLOW}⚠ NG Setup não encontrado nos logs${NC}"
fi

# Verificar problema de AMF Context
AMF_CONTEXT_ERROR=$(docker compose logs ueransim-gnb-rocket 2>&1 | grep -c "AMF context not found" 2>/dev/null | head -1 || echo "0")
if [ "$AMF_CONTEXT_ERROR" -gt 0 ] 2>/dev/null; then
    echo -e "${RED}⚠ Problema detectado: AMF context not found ($AMF_CONTEXT_ERROR ocorrência(s))${NC}"
    echo "   Execute: ./scripts/test-system-status.sh para mais detalhes"
else
    echo -e "${GREEN}✓ Nenhum erro de AMF context encontrado${NC}"
fi
echo ""

# Verificar associação PFCP
echo "Verificando associação PFCP (SMF <-> UPF)..."
PFCP_ASSOCIATED=$(docker compose logs open5gs-smf-rocket 2>&1 | grep -c "PFCP associated" 2>/dev/null | head -1 || echo "0")
if [ "$PFCP_ASSOCIATED" -gt 0 ] 2>/dev/null; then
    echo -e "${GREEN}✓ Associação PFCP estabelecida ($PFCP_ASSOCIATED UPF(s))${NC}"
else
    echo -e "${YELLOW}⚠ Associação PFCP não encontrada${NC}"
fi
echo ""

# Verificar se UE está conectado
echo "Verificando status do UE..."
if docker exec ueransim-ue-rocket pgrep -f "nr-ue" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ UE está rodando${NC}"
    
    # Verificar se UE tem IP
    UE_IP=$(docker exec ueransim-ue-rocket ip addr show 2>/dev/null | grep -oP 'inet \K10\.60\.\d+\.\d+' | head -1 || echo "")
    if [ -n "$UE_IP" ]; then
        echo -e "${GREEN}  ✓ UE possui IP: $UE_IP${NC}"
        # Verificar conectividade
        if docker exec ueransim-ue-rocket ping -c 1 -W 1 8.8.8.8 > /dev/null 2>&1; then
            echo -e "${GREEN}  ✓ Conectividade ativa${NC}"
            UE_CONNECTED=true
        else
            echo -e "${YELLOW}  ⚠ IP pode ser de sessão anterior (ping falhou)${NC}"
            UE_CONNECTED=false
        fi
    else
        echo -e "${YELLOW}  ⚠ UE não possui IP atribuído${NC}"
        UE_CONNECTED=false
    fi
    
    # Verificar se UE encontra células (pode depender da versão do UERANSIM)
    UE_CELL_FOUND=$(docker compose logs ueransim-ue-rocket 2>&1 | grep -c "Selected cell\|signal detected" 2>/dev/null | head -1 || echo "0")
    if [ "$UE_CELL_FOUND" -gt 0 ] 2>/dev/null; then
        echo -e "${GREEN}  ✓ UE encontrou células${NC}"
    else
        if [ "${UE_CONNECTED:-false}" = true ]; then
            echo -e "${YELLOW}  ⚠ UE não encontrou padrão 'Selected cell' nos logs, mas possui IP e conectividade (pode ser mudança de log na versão do UERANSIM)${NC}"
        else
            echo -e "${RED}  ✗ UE não encontrou células${NC}"
        fi
    fi
else
    echo -e "${RED}✗ UE não está rodando${NC}"
fi

echo ""
echo "=========================================="
echo "Healthcheck concluído"
echo "=========================================="
echo ""
echo "💡 Dicas:"
echo "  - Para verificação detalhada: ./scripts/test-system-status.sh"
echo "  - Para teste de conectividade: ./scripts/test_ue_connection.sh"
echo ""
