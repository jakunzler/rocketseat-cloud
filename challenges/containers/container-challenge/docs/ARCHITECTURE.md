# Arquitetura do Laboratório Open5GS Containerizado

## Visão Geral

Este laboratório implementa uma arquitetura 5G Core totalmente containerizada usando Open5GS, onde cada Network Function (NF) roda em um container Docker separado. Isso permite flexibilidade, escalabilidade e facilita experimentos com múltiplas UPFs.

## Componentes Principais

### Control Plane (Plano de Controle)

#### NRF (Network Repository Function)
- **Container:** `open5gs-nrf`
- **IP SBI:** 10.10.0.10
- **Porta:** 7777
- **Função:** Descoberta e registro de Network Functions

#### SCP (Service Communication Proxy)
- **Container:** `open5gs-scp`
- **IP SBI:** 10.10.0.200
- **Porta:** 7777
- **Função:** Roteamento e proxy de comunicação entre NFs

#### AMF (Access and Mobility Management Function)
- **Container:** `open5gs-amf`
- **IP SBI:** 10.10.0.11
- **IP N2:** 10.20.0.11
- **Porta SBI:** 7777
- **Porta NGAP:** 38412
- **Função:** Gerenciamento de acesso e mobilidade dos UEs

#### SMF (Session Management Function)
- **Container:** `open5gs-smf`
- **IP SBI:** 10.10.0.12
- **IP N4:** 10.40.0.12
- **Porta SBI:** 7777
- **Função:** Gerenciamento de sessões PDU e seleção de UPF

#### AUSF (Authentication Server Function)
- **Container:** `open5gs-ausf`
- **IP SBI:** 10.10.0.13
- **Porta:** 7777
- **Função:** Autenticação de UEs

#### UDM (Unified Data Management)
- **Container:** `open5gs-udm`
- **IP SBI:** 10.10.0.14
- **Porta:** 7777
- **Função:** Gerenciamento de dados de assinantes

#### UDR (Unified Data Repository)
- **Container:** `open5gs-udr`
- **IP SBI:** 10.10.0.15
- **Porta:** 7777
- **Função:** Repositório de dados de assinantes (usa MongoDB)

#### PCF (Policy Control Function)
- **Container:** `open5gs-pcf`
- **IP SBI:** 10.10.0.16
- **Porta:** 7777
- **Função:** Controle de políticas (usa MongoDB)

#### NSSF (Network Slice Selection Function)
- **Container:** `open5gs-nssf`
- **IP SBI:** 10.10.0.17
- **Porta:** 7777
- **Função:** Seleção de network slices

### User Plane (Plano de Usuário)

#### UPF-A
- **Container:** `open5gs-upf-a`
- **IP N3:** 10.30.0.21
- **IP N4:** 10.40.0.21
- **IP N6:** 10.50.0.21
- **Pool de IPs UE:** 10.60.0.0/17
- **Função:** Encaminhamento de dados dos UEs

- **Container:** `open5gs-upf-b`
- **IP N3:** 10.30.0.22
- **IP N4:** 10.40.0.22
- **IP N6:** 10.50.0.22
- **Pool de IPs UE:** 10.60.128.0/17
- **Função:** Encaminhamento de dados dos UEs (backup/load balancing)

### Radio Access Network (RAN)

#### gNB (UERANSIM)
- **Container:** `ueransim-gnb`
- **IP N2:** 10.20.0.100
- **IP N3:** 10.30.0.100
- **Função:** Simulação de estação base 5G

#### UE (UERANSIM)
- **Container:** `ueransim-ue`
- **IP UE:** 10.60.0.10 (alocado dinamicamente pelo UPF)
- **Função:** Simulação de User Equipment

### Data Network

#### DN (Data Network)
- **Container:** `open5gs-dn`
- **IP N6:** 10.50.0.100
- **Função:** Simula rede externa/internet com NAT

## Interfaces 5G

### N2 (NGAP)
- **Rede:** net-n2 (10.20.0.0/16)
- **Protocolo:** NGAP (NG Application Protocol)
- **Conecta:** gNB ↔ AMF
- **Porta:** 38412

### N3 (GTP-U)
- **Rede:** net-n3 (10.30.0.0/16)
- **Protocolo:** GTP-U (GPRS Tunnelling Protocol - User plane)
- **Conecta:** gNB ↔ UPF
- **Porta:** 2152

### N4 (PFCP)
- **Rede:** net-n4 (10.40.0.0/16)
- **Protocolo:** PFCP (Packet Forwarding Control Protocol)
- **Conecta:** SMF ↔ UPF
- **Porta:** 8805

### N6 (Data Network)
- **Rede:** net-n6 (10.50.0.0/16)
- **Protocolo:** IP
- **Conecta:** UPF ↔ DN
- **Função:** Acesso à internet/rede externa

### SBI (Service Based Interface)
- **Rede:** net-sbi (10.10.0.0/16)
- **Protocolo:** HTTP/2
- **Conecta:** Todas as NFs do control plane
- **Porta:** 7777

## Fluxo de Comunicação

### Registro de UE

1. **UE → gNB:** Inicia processo de registro
2. **gNB → AMF (N2):** Envia mensagem NGAP de registro
3. **AMF → AUSF (SBI):** Solicita autenticação
4. **AUSF → UDM (SBI):** Consulta dados de autenticação
5. **UDM → UDR (SBI):** Busca informações do assinante no MongoDB
6. **AMF → SMF (SBI):** Solicita criação de sessão PDU
7. **SMF → UPF (N4):** Estabelece sessão PFCP
8. **SMF → AMF (SBI):** Retorna informações da sessão
9. **AMF → gNB (N2):** Confirma registro e sessão
10. **gNB → UE:** Confirma registro

### Encaminhamento de Dados

1. **UE → gNB:** Dados do usuário
2. **gNB → UPF (N3):** Encapsula em túnel GTP-U
3. **UPF → DN (N6):** Desencapsula e encaminha para internet
4. **DN → UPF (N6):** Resposta da internet
5. **UPF → gNB (N3):** Encapsula em túnel GTP-U
6. **gNB → UE:** Entrega dados ao UE

## Seleção de UPF

O SMF pode selecionar entre múltiplas UPFs baseado em:

- **Load Balancing:** Distribuir carga entre UPF-A e UPF-B
- **Failover:** Se UPF-A falhar, usar UPF-B
- **DNN/APN:** Diferentes UPFs para diferentes DNNs
- **TAC (Tracking Area Code):** UPFs específicas por área
- **Cell ID:** UPFs específicas por célula

## Escalabilidade

### Adicionar Mais UPFs

A arquitetura permite adicionar facilmente mais UPFs:

1. Adicionar novo serviço no `docker-compose.yml`
2. Criar diretório de configuração
3. Configurar IPs únicos em cada rede
4. Atualizar SMF para incluir novo UPF na lista
5. Definir pool de IPs UE não sobreposto

### Adicionar Mais gNBs

Similar ao processo de adicionar UPFs:

1. Adicionar novo serviço `ueransim-gnb-X`
2. Configurar IPs únicos nas redes N2 e N3
3. Atualizar configuração do gNB

## Segurança

- **Redes isoladas:** Cada interface em rede Docker separada
- **Sem exposição de portas:** Apenas portas necessárias expostas
- **Privileged mode:** Apenas UPFs e DN precisam (para tunelamento e NAT)

## Monitoramento

- **Logs:** Cada serviço tem seu próprio diretório de logs
- **Healthchecks:** Docker healthchecks configurados para todos os serviços
- **Métricas:** Serviços expõem métricas na porta 9090 (Prometheus)

---

**Última Atualização:** 2025-12-17
