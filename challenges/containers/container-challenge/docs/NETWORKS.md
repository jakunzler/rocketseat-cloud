# Redes Docker Customizadas

## Visão Geral

Este documento detalha a estratégia de **redes Docker customizadas** implementada no projeto, demonstrando isolamento de tráfego, segurança e simulação de arquitetura 5G real.

---

## Arquitetura de Redes

### Redes Configuradas

O projeto utiliza **6 redes Docker customizadas** para diferentes interfaces 5G:

| Rede | CIDR | Gateway | Interface 5G | Protocolo |
|------|------|---------|---------------|-----------|
| `net-sbi` | 10.10.0.0/16 | 10.10.0.1 | SBI | HTTP/2 |
| `net-n2` | 10.20.0.0/16 | 10.20.0.1 | N2 | NGAP |
| `net-n3` | 10.30.0.0/16 | 10.30.0.1 | N3 | GTP-U |
| `net-n4` | 10.40.0.0/16 | 10.40.0.1 | N4 | PFCP |
| `net-n6` | 10.50.0.0/16 | 10.50.0.1 | N6 | IP |
| `ue-subnet` | 10.60.0.0/16 | 10.60.0.1 | UE | IP |

### Justificativa das Redes

#### 1. Isolamento de Tráfego
- ✅ Cada interface 5G em rede separada
- ✅ Tráfego isolado por tipo (controle vs. dados)
- ✅ Facilita troubleshooting e monitoramento

#### 2. Segurança
- ✅ Segmentação de rede (defense in depth)
- ✅ Limitação de acesso entre componentes
- ✅ Prevenção de acesso não autorizado

#### 3. Simulação Realista
- ✅ Simula arquitetura 5G real
- ✅ Interfaces separadas conforme especificação 3GPP
- ✅ Facilita migração para ambiente de produção

---

## Detalhamento das Redes

### net-sbi (Service Based Interface)

**CIDR:** 10.10.0.0/16  
**Gateway:** 10.10.0.1  
**Protocolo:** HTTP/2  
**Função:** Comunicação entre Network Functions do Control Plane

**Componentes Conectados:**
- NRF (10.10.0.10)
- SCP (10.10.0.200)
- AMF (10.10.0.11)
- SMF (10.10.0.12)
- AUSF (10.10.0.13)
- UDM (10.10.0.14)
- UDR (10.10.0.15)
- PCF (10.10.0.16)
- NSSF (10.10.0.17)
- MongoDB (10.10.0.20)

**Características:**
- ✅ Rede isolada para comunicação interna
- ✅ Sem exposição de portas para o host
- ✅ Comunicação via DNS (nomes de containers)

### net-n2 (NGAP Interface)

**CIDR:** 10.20.0.0/16  
**Gateway:** 10.20.0.1  
**Protocolo:** NGAP (NG Application Protocol)  
**Função:** Comunicação entre gNB e AMF

**Componentes Conectados:**
- AMF (10.20.0.11)
- gNB (10.20.0.100)
- UE (10.20.0.200)

**Características:**
- ✅ Interface de controle RAN
- ✅ Protocolo SCTP na porta 38412
- ✅ Comunicação crítica para registro de UE

### net-n3 (GTP-U Interface)

**CIDR:** 10.30.0.0/16  
**Gateway:** 10.30.0.1  
**Protocolo:** GTP-U (GPRS Tunnelling Protocol - User plane)  
**Função:** Túnel de dados entre gNB e UPF

**Componentes Conectados:**
- gNB (10.30.0.100)
- UPF (10.30.0.21)

**Características:**
- ✅ Interface de dados do usuário
- ✅ Protocolo UDP na porta 2152
- ✅ Encapsulamento GTP-U para dados do UE

### net-n4 (PFCP Interface)

**CIDR:** 10.40.0.0/16  
**Gateway:** 10.40.0.1  
**Protocolo:** PFCP (Packet Forwarding Control Protocol)  
**Função:** Controle de sessões entre SMF e UPF

**Componentes Conectados:**
- SMF (10.40.0.12)
- UPF (10.40.0.21)

**Características:**
- ✅ Interface de controle do user plane
- ✅ Protocolo UDP na porta 8805
- ✅ Estabelecimento e gerenciamento de sessões PDU

### net-n6 (Data Network Interface)

**CIDR:** 10.50.0.0/16  
**Gateway:** 10.50.0.1  
**Protocolo:** IP  
**Função:** Acesso à rede de dados externa (internet)

**Componentes Conectados:**
- UPF (10.50.0.21)
- DN (10.50.0.100)

**Características:**
- ✅ Interface para internet/rede externa
- ✅ NAT configurado no DN
- ✅ Roteamento de tráfego do UE para internet

### ue-subnet (UE Subnet)

**CIDR:** 10.60.0.0/16  
**Gateway:** 10.60.0.1  
**Protocolo:** IP  
**Função:** Subnet para IPs alocados aos UEs

**Componentes Conectados:**
- UE (10.60.0.10 - IP estático inicial)
- UPF-A (gateway 10.60.0.1/17)

**Características:**
- ✅ Pool de IPs para UEs
- ✅ IPs alocados dinamicamente pelo UPF
- ✅ Roteamento via ogstun interface

---

## Gerenciamento de Redes

### Listar Redes

```bash
# Listar todas as redes
docker network ls

# Listar redes do projeto
docker network ls | grep container-challenge
```

### Inspecionar Rede

```bash
# Inspecionar rede específica
docker network inspect container-challenge_net-sbi

# Ver containers conectados
docker network inspect container-challenge_net-sbi --format '{{ range .Containers }}{{ .Name }} {{ end }}'
```

### Conectar Container a Rede

```bash
# Conectar container existente a rede
docker network connect container-challenge_net-sbi <container-name>

# Desconectar
docker network disconnect container-challenge_net-sbi <container-name>
```

### Testar Conectividade

```bash
# Testar ping entre containers
docker compose exec amf ping -c 3 10.10.0.10  # AMF → NRF

# Testar conectividade de rede específica
docker compose exec smf ping -c 3 10.40.0.21  # SMF → UPF-A (N4)

# Verificar rota
docker compose exec amf ip route show
```

### Remover Redes

```bash
# Remover rede específica (após parar containers)
docker network rm container-challenge_net-sbi

# Remover todas as redes do projeto
docker compose down
```

---

## Boas Práticas

### 1. Isolamento de Tráfego

- ✅ Cada interface em rede separada
- ✅ Limitar acesso apenas ao necessário
- ✅ Não expor portas desnecessárias

### 2. Nomenclatura Consistente

- ✅ Usar prefixo do projeto (`container-challenge_`)
- ✅ Nomes descritivos (`net-sbi`, `net-n2`, etc.)
- ✅ Documentar IPs e gateways

### 3. Monitoramento

```bash
# Monitorar tráfego em rede específica
docker network inspect container-challenge_net-sbi --format '{{ .Containers }}'

# Ver estatísticas de rede
docker stats --no-stream
```

---

## Troubleshooting

### Container não consegue se conectar à rede

**Problema:** Container não consegue acessar outros containers na mesma rede.

**Solução:**
1. Verificar se container está na rede:
   ```bash
   docker network inspect container-challenge_net-sbi | grep <container-name>
   ```

2. Verificar DNS:
   ```bash
   docker compose exec amf nslookup nrf
   ```

3. Verificar conectividade:
   ```bash
   docker compose exec amf ping -c 3 nrf
   ```

### Rede não é criada

**Problema:** Erro ao criar rede customizada.

**Solução:**
1. Verificar conflito de CIDR:
   ```bash
   docker network ls
   ip route show
   ```

2. Limpar redes órfãs:
   ```bash
   docker network prune
   ```

3. Recriar rede:
   ```bash
   docker compose down
   docker compose up -d
   ```

### Conflito de IP

**Problema:** IP já está em uso.

**Solução:**
1. Verificar IPs em uso:
   ```bash
   docker network inspect container-challenge_net-sbi --format '{{ range .Containers }}{{ .IPv4Address }} {{ end }}'
   ```

2. Ajustar IP no `docker-compose.yml`:
   ```yaml
   networks:
     net-sbi:
       ipv4_address: 10.10.0.XX  # Usar IP disponível
   ```

---

## Referências

- [Docker Networking Documentation](https://docs.docker.com/network/)
- [3GPP TS 23.501 - System Architecture](https://www.3gpp.org/ftp/Specs/archive/23_series/23.501/)
- [Docker Compose Networks](https://docs.docker.com/compose/networking/)

---

**Última Atualização:** 2026-01-16

