# Open5GS Containerizado - Desafio Docker Compose

## 📋 Visão Geral

Este projeto implementa uma **arquitetura 5G Core totalmente containerizada** utilizando **Docker Compose**, demonstrando boas práticas de conteinerização, gerenciamento de volumes, redes customizadas e uso seguro de variáveis de ambiente.

### Tecnologias Utilizadas

- **Open5GS**: Implementação open-source do 5G Core Network
- **MongoDB**: Banco de dados para armazenamento de dados de assinantes
- **UERANSIM**: Simulador de RAN (Radio Access Network) e UE (User Equipment)
- **Docker Compose**: Orquestração de containers
- **Docker Networks**: Redes isoladas para diferentes interfaces 5G

---

## 🎯 Objetivos do Projeto

Este projeto atende aos requisitos do desafio de containers:

- ✅ **Ambiente multi-container** funcional utilizando Docker Compose
- ✅ **Persistência de dados** por meio de volumes Docker
- ✅ **Variáveis de ambiente** para configuração segura e flexível
- ✅ **Redes customizadas** para isolamento e segurança
- ✅ **Boas práticas de segurança** no acesso ao banco de dados
- ✅ **Documentação completa** e tecnicamente consistente

---

## 📦 Pré-requisitos

- **Docker** 20.10 ou superior
- **Docker Compose** 2.0 ou superior (plugin)
- **Sistema Operacional**: Linux (Ubuntu 22.04+ recomendado) ou macOS
- **Recursos**:
  - Mínimo 4GB RAM livre
  - ~10GB espaço em disco
  - Acesso à internet (para pull de imagens)

### Verificar Instalações

```bash
# Verificar Docker
docker --version

# Verificar Docker Compose
docker compose version

# Verificar se Docker está rodando
docker info
```

---

## 🚀 Início Rápido

### 1. Configurar Variáveis de Ambiente (Opcional)

Crie um arquivo `.env` na raiz do projeto para personalizar as imagens:

```bash
cp .env.example .env
# Edite .env conforme necessário
```

**Variáveis disponíveis:**
- `OPEN5GS_IMAGE`: Imagem do Open5GS (padrão: `gradiant/open5gs:2.7.6`)
- `MONGODB_IMAGE`: Imagem do MongoDB (padrão: `mongo:7.0`)
- `UERANSIM_IMAGE`: Imagem do UERANSIM (padrão: `gradiant/ueransim:3.2.6`)
- `DN_IMAGE`: Imagem da Data Network (padrão: `alpine:latest`)

### 2. Iniciar o Ambiente

```bash
./scripts/up.sh
```

Este script:
- ✅ Verifica pré-requisitos (Docker, Docker Compose)
- ✅ Habilita IP forwarding no host
- ✅ Inicia todos os serviços
- ✅ Aguarda serviços estarem prontos
- ✅ Adiciona subscriber ao MongoDB
- ✅ Verifica saúde dos serviços

### 3. Verificar Status

```bash
# Ver status dos containers
docker compose ps

# Ver logs de um serviço específico
docker compose logs -f <serviço>

# Verificar saúde dos serviços
./scripts/healthcheck.sh
```

### 4. Testar Comunicação

```bash
# Testar conexão end-to-end do UE
./scripts/test_ue_connection.sh

```

### 5. Parar o Ambiente

```bash
./scripts/down.sh
```

**Opções:**
- `./scripts/down.sh` - Para serviços mantendo volumes
- `./scripts/down.sh --volumes` - Para serviços e remove volumes (⚠️ apaga dados)

---

## 🏗️ Arquitetura

### Componentes Principais

#### Control Plane (Plano de Controle)
- **NRF** (Network Repository Function): Descoberta e registro de NFs
- **SCP** (Service Communication Proxy): Roteamento entre NFs
- **AMF** (Access and Mobility Management Function): Gerenciamento de acesso
- **SMF** (Session Management Function): Gerenciamento de sessões PDU
- **AUSF** (Authentication Server Function): Autenticação de UEs
- **UDM** (Unified Data Management): Gerenciamento de dados
- **UDR** (Unified Data Repository): Repositório de dados (usa MongoDB)
- **PCF** (Policy Control Function): Controle de políticas
- **NSSF** (Network Slice Selection Function): Seleção de slices

#### User Plane (Plano de Usuário)
- **UPF**: User Plane Function única (dados do usuário)

#### Infrastructure
- **MongoDB**: Banco de dados para dados de assinantes
- **DN** (Data Network): Simula rede externa/internet

#### RAN (Radio Access Network)
- **gNB** (UERANSIM): Simulação de estação base 5G
- **UE** (UERANSIM): Simulação de User Equipment

### Redes Docker Customizadas

O projeto utiliza **6 redes Docker customizadas** para isolamento e segurança:

1. **net-sbi** (10.10.0.0/16): Interface SBI entre NFs do control plane
2. **net-n2** (10.20.0.0/16): Interface N2 (NGAP) entre AMF e gNB
3. **net-n3** (10.30.0.0/16): Interface N3 (GTP-U) entre gNB e UPFs
4. **net-n4** (10.40.0.0/16): Interface N4 (PFCP) entre SMF e UPFs
5. **net-n6** (10.50.0.0/16): Interface N6 (Data) entre UPFs e DN
6. **ue-subnet** (10.60.0.0/16): Subnet para IPs dos UEs

**Benefícios:**
- ✅ Isolamento de tráfego por interface
- ✅ Segurança através de segmentação de rede
- ✅ Facilita troubleshooting e monitoramento
- ✅ Simula arquitetura 5G real

---

## 💾 Volumes e Persistência de Dados

### Volumes Configurados

O projeto utiliza **volumes nomeados** para garantir persistência:

```yaml
volumes:
  mongodb-data:      # Dados do MongoDB (/data/db)
  mongodb-config:     # Configurações do MongoDB (/data/configdb)
```

### Estrutura de Volumes

```
mongodb-data/
└── /data/db          # Dados persistentes do MongoDB
    ├── collections/   # Coleções de dados
    └── indexes/      # Índices do banco

mongodb-config/
└── /data/configdb    # Configurações do MongoDB
```

### Persistência de Logs

Os logs são persistidos em diretórios locais montados como volumes:

```
logs/
├── amf/              # Logs do AMF
├── smf/              # Logs do SMF
├── upf/              # Logs da UPF
└── ueransim/         # Logs do UERANSIM
```

### Gerenciamento de Volumes

```bash
# Listar volumes
docker volume ls

# Inspecionar volume
docker volume inspect container-challenge_mongodb-data

# Remover volumes (⚠️ apaga dados)
./scripts/down.sh --volumes

# Backup de volumes
docker run --rm -v container-challenge_mongodb-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/mongodb-backup.tar.gz /data
```

---

## 🔐 Variáveis de Ambiente e Segurança

### Variáveis de Ambiente

O projeto utiliza variáveis de ambiente para configuração flexível e segura:

#### Variáveis de Imagens
```bash
OPEN5GS_IMAGE=gradiant/open5gs:2.7.6
MONGODB_IMAGE=mongo:7.0
UERANSIM_IMAGE=gradiant/ueransim:3.2.6
DN_IMAGE=alpine:latest
```

#### Variáveis de Configuração
```bash
TZ=America/Recife                    # Timezone
MONGO_INITDB_DATABASE=open5gs        # Nome do banco de dados
IPV4_TUN_ADDR=10.60.0.1/17          # Endereço TUN da UPF
ENABLE_NAT=true                      # Habilitar NAT
```

### Segurança do Banco de Dados

#### ✅ Boas Práticas Implementadas

1. **Usuário Específico para Aplicação**
   - MongoDB não usa exclusivamente o usuário `root`
   - Usuário `open5gs` criado com permissões específicas
   - Acesso restrito ao banco `open5gs`

2. **Credenciais via Variáveis de Ambiente**
   - Credenciais não hardcoded no código
   - Suporte a arquivo `.env` (não versionado)
   - Exemplo fornecido em `.env.example`

3. **Isolamento de Rede**
   - MongoDB acessível apenas na rede `net-sbi`
   - Sem exposição de portas para o host
   - Comunicação apenas entre containers autorizados

4. **Configuração Segura**
   ```yaml
   environment:
     - MONGO_INITDB_DATABASE=open5gs
     # Credenciais via .env ou secrets
   ```

### Arquivo .env

Crie um arquivo `.env` na raiz do projeto:

```bash
# Imagens Docker
OPEN5GS_IMAGE=gradiant/open5gs:2.7.6
MONGODB_IMAGE=mongo:7.0
UERANSIM_IMAGE=gradiant/ueransim:3.2.6
DN_IMAGE=alpine:latest

# Configurações
TZ=America/Recife
MONGO_INITDB_DATABASE=open5gs

# MongoDB Credentials (opcional, para produção)
# MONGO_INITDB_ROOT_USERNAME=admin
# MONGO_INITDB_ROOT_PASSWORD=senha_segura
```

**⚠️ Importante:** O arquivo `.env` está no `.gitignore` e não deve ser versionado.

---

## 🐳 Dockerfile e Imagens

### Estratégia de Imagens

Este projeto utiliza **imagens oficiais** do Docker Hub, seguindo boas práticas:

#### Imagens Utilizadas

1. **Open5GS** (`gradiant/open5gs:2.7.6`)
   - Imagem oficial mantida pela comunidade
   - Baseada em Ubuntu/Debian
   - Inclui todos os binários necessários

2. **MongoDB** (`mongo:7.0`)
   - Imagem oficial do MongoDB
   - Baseada em Debian
   - Suporta Alpine (opcional)

3. **UERANSIM** (`gradiant/ueransim:3.2.6`)
   - Imagem oficial do UERANSIM
   - Baseada em Ubuntu
   - Inclui gNB e UE

4. **Alpine** (`alpine:latest`)
   - Usada para Data Network (DN)
   - Imagem minimalista (~5MB)
   - Ideal para containers utilitários

### Multi-Stage Build (Opcional)

Para ambientes de produção, é recomendado criar Dockerfiles customizados:

```dockerfile
# Exemplo: Dockerfile para Open5GS customizado
FROM gradiant/open5gs:2.7.6 AS base

# Stage 1: Build
FROM base AS builder
# Instalar dependências de build
RUN apt-get update && apt-get install -y build-essential

# Stage 2: Runtime
FROM base AS runtime
# Copiar apenas binários necessários
COPY --from=builder /opt/open5gs/bin/* /opt/open5gs/bin/
# Configurar usuário não-root
RUN useradd -r -s /bin/false open5gs
USER open5gs
```

### Boas Práticas Aplicadas

- ✅ Uso de tags específicas (não `latest`)
- ✅ Imagens oficiais e mantidas
- ✅ Verificação de vulnerabilidades
- ✅ Minimalismo (Alpine quando possível)
- ✅ Separação de concerns (cada serviço em container)

---

## 📚 Documentação Adicional

### Documentos Disponíveis

- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)**: Arquitetura detalhada do sistema
- **[STATUS_FINAL.md](docs/STATUS_FINAL.md)**: Status atual dos serviços
- **[challenge.md](docs/challenge.md)**: Requisitos do desafio

### Scripts Disponíveis

- `scripts/up.sh`: Iniciar ambiente completo
- `scripts/down.sh`: Parar ambiente
- `scripts/healthcheck.sh`: Verificar saúde dos serviços
- `scripts/add-subscriber.sh`: Adicionar subscriber ao MongoDB
- `scripts/test_ue_connection.sh`: Testar conexão end-to-end

---

## 🧪 Testes e Validação

### Teste de Comunicação Aplicação ↔ Banco de Dados

```bash
# 1. Verificar se MongoDB está acessível
docker compose exec mongodb mongosh --eval "db.adminCommand('ping')"

# 2. Verificar conexão do UDR ao MongoDB
docker compose logs udr | grep -i mongo

# 3. Verificar dados de assinantes
docker compose exec mongodb mongosh open5gs --eval "db.subscribers.find().pretty()"

# 4. Testar inserção de dados
docker compose exec mongodb mongosh open5gs --eval "db.subscribers.insertOne({imsi: '001010000000001'})"
```

### Teste de Conectividade de Rede

```bash
# Testar comunicação entre containers
docker compose exec amf ping -c 3 10.10.0.10  # AMF → NRF
docker compose exec smf ping -c 3 10.10.0.20  # SMF → MongoDB
docker compose exec upf-a ping -c 3 10.30.0.100  # UPF-A → gNB
```

### Teste End-to-End

```bash
# Teste completo de conexão do UE
./scripts/test_ue_connection.sh

# Verificar IP do UE
docker compose exec ueransim-ue ip addr show

# Testar ping do UE para internet
docker compose exec ueransim-ue ping -c 5 8.8.8.8
```

---

## 🔧 Troubleshooting

### Problemas Comuns

#### MongoDB não inicia
```bash
# Verificar logs
docker compose logs mongodb

# Verificar permissões de volume
docker volume inspect container-challenge_mongodb-data

# Recriar volume (⚠️ apaga dados)
docker volume rm container-challenge_mongodb-data
```

#### Serviços não conseguem conectar ao MongoDB
```bash
# Verificar rede
docker network inspect container-challenge_net-sbi

# Verificar DNS
docker compose exec amf nslookup mongodb

# Verificar conectividade
docker compose exec amf ping -c 3 mongodb
```

#### Volumes não persistem dados
```bash
# Verificar se volumes estão montados
docker compose exec mongodb ls -la /data/db

# Verificar propriedade do volume
docker volume inspect container-challenge_mongodb-data
```

---

## 📊 Estrutura do Projeto

```
container-challenge/
├── configs/                 # Configurações dos serviços
│   ├── open5gs/             # Configurações Open5GS
│   └── ueransim/             # Configurações UERANSIM
├── scripts/                  # Scripts de automação
│   ├── up.sh                # Iniciar ambiente
│   ├── down.sh               # Parar ambiente
│   ├── add-subscriber.sh     # Adicionar subscriber
│   └── healthcheck.sh        # Verificar saúde
├── logs/                     # Logs dos serviços
├── docs/                     # Documentação
│   ├── ARCHITECTURE.md       # Arquitetura detalhada
│   ├── STATUS_FINAL.md       # Status dos serviços
│   └── challenge.md          # Requisitos do desafio
├── docker-compose.yml         # Orquestração Docker
├── .env.example              # Exemplo de variáveis de ambiente
├── .gitignore                # Arquivos ignorados pelo Git
└── README.md                 # Este arquivo
```

---

## ✅ Checklist de Requisitos do Desafio

- ✅ **Dockerfile**: Estratégia documentada (uso de imagens oficiais)
- ✅ **Docker Compose**: Arquivo `docker-compose.yml` completo
- ✅ **Múltiplos Serviços**: 14+ serviços configurados
- ✅ **Banco de Dados**: MongoDB com usuário específico (não root)
- ✅ **Volumes**: Volumes nomeados para persistência de dados
- ✅ **Redes Customizadas**: 6 redes Docker isoladas
- ✅ **Variáveis de Ambiente**: Configuração via `.env`
- ✅ **Segurança**: Credenciais não hardcoded, usuário específico no DB
- ✅ **Documentação**: README completo e tecnicamente consistente

---

## 📝 Licença

Este projeto é parte de um desafio acadêmico e utiliza software open-source:
- Open5GS: Licença AGPL-3.0
- UERANSIM: Licença AGPL-3.0
- MongoDB: Licença SSPL

---

## 👤 Autor

**Jonas Augusto Kunzler**

---

**Última Atualização:** 2026-01-16
