#!/bin/bash
#
# Script para verificar o status real do sistema
# Detecta problemas conhecidos e fornece informações detalhadas
#
# Autor: Jonas Augusto Kunzler
# Data: 2026-01-15

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Usar nomes de serviços do docker-compose.yml
UE_CONTAINER="ueransim-ue"
GNB_CONTAINER="ueransim-gnb"
AMF_CONTAINER="amf"
SMF_CONTAINER="smf"

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Verificação de Status do Sistema"
echo "Open5GS Containerized"
echo "=========================================="
echo ""

# 1. Verificar containers
echo "📋 1. Status dos Containers"
echo "--------------------------------------------"
if docker compose ps | grep -q "${UE_CONTAINER}.*Up"; then
    echo -e "${GREEN}✅ UE: Rodando${NC}"
else
    echo -e "${RED}❌ UE: Não está rodando${NC}"
fi

if docker compose ps | grep -q "${GNB_CONTAINER}.*Up"; then
    echo -e "${GREEN}✅ gNB: Rodando${NC}"
else
    echo -e "${RED}❌ gNB: Não está rodando${NC}"
fi

if docker compose ps | grep -q "${AMF_CONTAINER}.*Up"; then
    echo -e "${GREEN}✅ AMF: Rodando${NC}"
else
    echo -e "${RED}❌ AMF: Não está rodando${NC}"
fi

if docker compose ps | grep -q "${SMF_CONTAINER}.*Up"; then
    echo -e "${GREEN}✅ SMF: Rodando${NC}"
else
    echo -e "${RED}❌ SMF: Não está rodando${NC}"
fi
echo ""

# 2. Verificar NG Setup
echo "📡 2. Conexão N2 (gNB <-> AMF)"
echo "--------------------------------------------"
NG_SETUP_SUCCESS=$(docker compose logs $GNB_CONTAINER 2>&1 | grep -c "NG Setup procedure is successful" 2>/dev/null | head -1 || echo "0")
if [ "$NG_SETUP_SUCCESS" -gt 0 ] 2>/dev/null; then
    echo -e "${GREEN}✅ NG Setup bem-sucedido ($NG_SETUP_SUCCESS vez(es))${NC}"
    LAST_NG_SETUP=$(docker compose logs $GNB_CONTAINER 2>&1 | grep "NG Setup procedure is successful" | tail -1 | awk '{print $1, $2}' || echo "N/A")
    echo "   Último NG Setup: $LAST_NG_SETUP"
else
    echo -e "${RED}❌ NG Setup não encontrado nos logs${NC}"
fi

AMF_ACCEPTED=$(docker compose logs $AMF_CONTAINER 2>&1 | grep -c "gNB-N2 accepted" 2>/dev/null | head -1 || echo "0")
if [ "$AMF_ACCEPTED" -gt 0 ] 2>/dev/null; then
    echo -e "${GREEN}✅ AMF aceitou conexão do gNB ($AMF_ACCEPTED vez(es))${NC}"
else
    echo -e "${YELLOW}⚠️  AMF não aceitou conexão do gNB${NC}"
fi
echo ""

# 3. Verificar problema de AMF Context
echo "🔍 3. Problema de AMF Context"
echo "--------------------------------------------"
AMF_CONTEXT_ERROR=$(docker compose logs $GNB_CONTAINER 2>&1 | grep -c "AMF context not found" 2>/dev/null | head -1 || echo "0")
if [ "$AMF_CONTEXT_ERROR" -gt 0 ] 2>/dev/null; then
    echo -e "${RED}❌ Problema detectado: AMF context not found ($AMF_CONTEXT_ERROR ocorrência(s))${NC}"
    echo "   Este é um problema conhecido do UERANSIM v3.2.7"
    echo "   NG Setup é bem-sucedido, mas o contexto não é armazenado"
    LAST_ERROR=$(docker compose logs $GNB_CONTAINER 2>&1 | grep "AMF context not found" | tail -1 | awk '{print $1, $2}' || echo "N/A")
    echo "   Última ocorrência: $LAST_ERROR"
    echo ""
    echo "   Possíveis causas:"
    echo "   - Bug do UERANSIM v3.2.7"
    echo "   - AMF não está enviando AMF ID na resposta do NG Setup"
    echo "   - Problema de timing no armazenamento do contexto"
else
    echo -e "${GREEN}✅ Nenhum erro de AMF context encontrado${NC}"
fi
echo ""

# 4. Verificar status do UE
echo "📱 4. Status do UE"
echo "--------------------------------------------"
UE_IP=$(docker compose exec -T $UE_CONTAINER ip addr show 2>/dev/null | grep -oP 'inet \K10\.60\.\d+\.\d+' | head -1 || echo "")
if [ -n "$UE_IP" ]; then
    echo -e "${GREEN}✅ UE possui IP: $UE_IP${NC}"
    echo "   ⚠️  Nota: IP pode ser de sessão anterior"
else
    echo -e "${YELLOW}⚠️  UE não possui IP atribuído${NC}"
fi

# Verificar se UE encontra células
UE_CELL_FOUND=$(docker compose logs $UE_CONTAINER 2>&1 | grep -c "Selected cell\|signal detected" 2>/dev/null | head -1 || echo "0")
if [ "$UE_CELL_FOUND" -gt 0 ] 2>/dev/null; then
    echo -e "${GREEN}✅ UE encontrou células ($UE_CELL_FOUND vez(es))${NC}"
else
    echo -e "${RED}❌ UE não encontrou células${NC}"
fi

# Verificar estado de registro
UE_REG_STATE=$(docker compose logs $UE_CONTAINER 2>&1 | grep "UE switches to state" | tail -1 | grep -oP "\[MM-[^\]]+\]" || echo "")
if [ -n "$UE_REG_STATE" ]; then
    if echo "$UE_REG_STATE" | grep -q "REGISTERED"; then
        echo -e "${GREEN}✅ UE está registrado: $UE_REG_STATE${NC}"
    elif echo "$UE_REG_STATE" | grep -q "ATTEMPTING-REGISTRATION"; then
        echo -e "${YELLOW}⚠️  UE tentando registro: $UE_REG_STATE${NC}"
    else
        echo -e "${RED}❌ UE não está registrado: $UE_REG_STATE${NC}"
    fi
fi
echo ""

# 5. Verificar sessão PDU
echo "🔗 5. Sessão PDU"
echo "--------------------------------------------"
PFCP_ASSOCIATED=$(docker compose logs $SMF_CONTAINER 2>&1 | grep -c "PFCP associated" 2>/dev/null | head -1 || echo "0")
if [ "$PFCP_ASSOCIATED" -gt 0 ] 2>/dev/null; then
    echo -e "${GREEN}✅ Associação PFCP estabelecida ($PFCP_ASSOCIATED UPF(s))${NC}"
else
    echo -e "${YELLOW}⚠️  Associação PFCP não encontrada${NC}"
fi

# Verificar se há sessão PDU ativa (indireto via IP do UE)
if [ -n "$UE_IP" ]; then
    # Tentar ping para verificar se rota está ativa
    if docker compose exec -T $UE_CONTAINER ping -c 1 -W 1 8.8.8.8 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Conectividade ativa (ping para 8.8.8.8 OK)${NC}"
        echo "   Isso indica que sessão PDU está funcionando"
    else
        echo -e "${YELLOW}⚠️  Sem conectividade (ping falhou)${NC}"
        echo "   IP pode ser de sessão anterior"
    fi
fi
echo ""

# 6. Resumo e recomendações
echo "=========================================="
echo "Resumo e Recomendações"
echo "=========================================="
echo ""

if [ "$AMF_CONTEXT_ERROR" -gt 0 ] 2>/dev/null; then
    echo -e "${RED}⚠️  PROBLEMA CRÍTICO DETECTADO${NC}"
    echo ""
    echo "O sistema tem o problema conhecido de 'AMF context not found'."
    echo "Isso impede o registro de novos UEs, mesmo com NG Setup bem-sucedido."
    echo ""
    echo "Recomendações:"
    echo "1. Verificar se há versão mais recente do UERANSIM"
    echo "2. Verificar configuração do GUAMI no AMF"
    echo "3. Considerar usar versão diferente do UERANSIM (3.2.6 ou 3.2.4)"
    echo "4. Verificar logs detalhados: docker compose logs $GNB_CONTAINER | grep -i 'AMF\|NG Setup'"
    echo ""
elif [ -z "$UE_IP" ] || [ "$UE_CELL_FOUND" -eq 0 ] 2>/dev/null; then
    echo -e "${YELLOW}⚠️  PROBLEMAS DETECTADOS${NC}"
    echo ""
    echo "O UE não está funcionando corretamente:"
    if [ -z "$UE_IP" ]; then
        echo "- UE não possui IP"
    fi
    if [ "$UE_CELL_FOUND" -eq 0 ] 2>/dev/null; then
        echo "- UE não encontra células"
    fi
    echo ""
    echo "Verifique:"
    echo "1. Se o UE está na mesma rede que o gNB (net-n2)"
    echo "2. Se o TAC está correto (deve ser 7)"
    echo "3. Logs do UE: docker compose logs $UE_CONTAINER"
    echo ""
else
    echo -e "${GREEN}✅ Sistema parece estar funcionando${NC}"
    echo ""
    echo "Todos os componentes estão operacionais."
    if [ -n "$UE_IP" ]; then
        echo "UE possui IP e conectividade."
    fi
fi

echo "=========================================="
echo "Fim da Verificação"
echo "=========================================="

